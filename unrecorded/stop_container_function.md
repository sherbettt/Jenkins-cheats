# Создание общей функции остановки контейнера

## Цель
Вынести шаг выключения контейнера в отдельную функцию, чтобы использовать её в post блоке `always` (или `cleanup`) для гарантированной остановки контейнера после сборки.

## Шаг 1: Добавление функции в vars/build.groovy
Добавьте в конец файла `vars/build.groovy` (перед `return this`) новую функцию:

```groovy
// Остановка контейнера после сборки
def stopContainer(String proxIP, String containerID) {
    sh label: 'Stop container', script: """
        ssh -o StrictHostKeyChecking=no root@${proxIP} '
            set -e
            echo "Останавливаем контейнер ${containerID}"
            pct stop ${containerID} 2>/dev/null || echo "Контейнер уже остановлен или не существует"
        '
    """
}
```

## Шаг 2: Использование функции в JenkinsFile
В JenkinsFile добавьте вызов этой функции в post блоке `always` (или `cleanup`). Это гарантирует, что контейнер будет остановлен независимо от результата сборки.

### Пример post блока с остановкой контейнера:
```groovy
post {
    always {
        script {
            // Останавливаем контейнер после завершения сборки
            build.stopContainer(env.PROX4, env.CT_ID)
        }
        // Другие действия, которые должны выполняться всегда (очистка, уведомления и т.д.)
    }
    success {
        // Действия при успешной сборке
    }
    failure {
        // Действия при неудачной сборке
    }
    aborted {
        // Действия при отмене сборки
    }
}
```

## Шаг 3: Интеграция с существующим post блоком
Если у вас уже есть post блок с уведомлениями и Allure, добавьте `always` секцию перед `success`, `failure`, `aborted`.

Пример полного post блока с остановкой контейнера, Allure и Telegram:

```groovy
post {
    always {
        script {
            build.stopContainer(env.PROX4, env.CT_ID)
        }
    }
    success {
        withCredentials([
            string(credentialsId: 'TGbotSecret', variable: 'TOKEN'),
            string(credentialsId: 'TGChatID', variable: 'CHAT_ID')
        ]) {
            allure([
                includeProperties: false,
                jdk: '',
                report: 'allure-report/',
                results: [[path: 'allure-results/']]
            ])
            script {
                if (fileExists('test-logs/')) {
                    archiveArtifacts artifacts: 'test-logs/**'
                }
            }
            sh 'curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="✅ Сборка $BUILD_ID Выполнена успешно проект $JOB_NAME подробнее: $BUILD_URL"'
            echo "Длительность сборки: ${currentBuild.duration} ms"
        }
    }
    aborted {
        withCredentials([
            string(credentialsId: 'TGbotSecret', variable: 'TOKEN'),
            string(credentialsId: 'TGChatID', variable: 'CHAT_ID')
        ]) {
            sh 'curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="⛔ Сборка $BUILD_ID Отменена проект $JOB_NAME подробнее: $BUILD_URL"'
        }
    }
    failure {
        withCredentials([
            string(credentialsId: 'TGbotSecret', variable: 'TOKEN'),
            string(credentialsId: 'TGChatID', variable: 'CHAT_ID')
        ]) {
            allure([
                includeProperties: false,
                jdk: '',
                report: 'allure-report/',
                results: [[path: 'allure-results/']]
            ])
            script {
                if (fileExists('test-logs/')) {
                    archiveArtifacts artifacts: 'test-logs/**'
                }
            }
            sh 'curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="❌ Ошибка при сборке $BUILD_ID проект $JOB_NAME подробнее: $BUILD_URL"'
        }
    }
}
```

## Шаг 4: Проверка
Убедитесь, что переменные `env.PROX4` и `env.CT_ID` определены в environment блоках JenkinsFile. Если вы используете другой прокси-хост (например, `PROX5`), измените соответствующим образом.

## Преимущества подхода
- **Единая точка управления**: Функция `stopContainer` централизует логику остановки.
- **Гарантированное выполнение**: Секция `always` выполняется при любом исходе сборки.
- **Повторное использование**: Функцию можно вызывать из других мест (например, при ошибке на ранних стадиях).

## Примечание
Если контейнер должен оставаться запущенным для отладки, можно добавить параметр сборки (boolean) для пропуска остановки.