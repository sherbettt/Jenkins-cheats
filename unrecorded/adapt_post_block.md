# Адаптация post блока для вашего Jenkins pipeline

## Текущая ситуация
У вас есть post блок из другого проекта (`run_auto_tests`), который:
1. Генерирует Allure отчёт из результатов тестов.
2. Архивирует логи.
3. Отправляет уведомления в Telegram.

В вашем проекте (`cycle_single_node`) тесты запускаются внутри контейнера, и результаты остаются там. Нужно адаптировать пути и обеспечить копирование результатов на хост Jenkins.

## Шаг 1: Модификация функции testLK для копирования результатов
Добавьте в функцию `testLK` (в файле `vars/build.groovy`) копирование результатов Allure и логов на хост Jenkins.

### Изменения в `vars/build.groovy`:
Найдите функцию `testLK` и после закрывающей кавычки SSH добавьте:

```groovy
        # Копируем результаты Allure из контейнера на хост Jenkins
        mkdir -p allure-results
        scp -o StrictHostKeyChecking=no -r root@${containerIP}:/root/ansible-proj/runtel_auto_tests/test_results/allure-results/* allure-results/ 2>/dev/null || echo "Результаты Allure не найдены, пропускаем копирование"
        # Копируем логи если есть
        mkdir -p test-logs
        scp -o StrictHostKeyChecking=no -r root@${containerIP}:/root/ansible-proj/runtel_auto_tests/test_results/logs/* test-logs/ 2>/dev/null || echo "Логи не найдены, пропускаем копирование"
```

Это создаст директории `allure-results` и `test-logs` в workspace Jenkins и скопирует туда данные из контейнера.

## Шаг 2: Адаптация post блока в JenkinsFile
Замените текущий post блок (или добавьте его, если отсутствует) на адаптированную версию.

### Адаптированный post блок:
```groovy
post {
    success {
        withCredentials([
            string(credentialsId: 'TGbotSecret', variable: 'TOKEN'),
            string(credentialsId: 'TGChatID', variable: 'CHAT_ID')
        ]) {
            allure([
                includeProperties: false,
                jdk: '',
                report: 'allure-report/',
                results: [[path: 'allure-results/']]  // путь относительно workspace
            ])
            script {
                if (fileExists('test-logs/')) {
                    archiveArtifacts artifacts: 'test-logs/**'
                } else {
                    echo "Директория с логами не существует, архивация пропущена"
                }
            }
            sh 'curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="✅ Сборка $BUILD_ID Выполнена успешно проект $JOB_NAME подробнее: $BUILD_URL"'
            echo "Длительность сборки: ${currentBuild.duration} ms"

                sh label: 'Выключить контейнер', script: """
                    echo "Выключаем контейнер ${env.CT_IP}"
                    ssh -o StrictHostKeyChecking=no root@${env.PROX4} '
                        set -e
                        pct stop ${env.CT_ID}
                    '
                """
        }
    }
    
    aborted {
        withCredentials([
            string(credentialsId: 'TGbotSecret', variable: 'TOKEN'),
            string(credentialsId: 'TGChatID', variable: 'CHAT_ID')
        ]) {
            sh 'curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="⛔ Сборка $BUILD_ID Прошла неудачно проект $JOB_NAME подробнее: $BUILD_URL"'

                sh label: 'Выключить контейнер', script: """
                    echo "Выключаем контейнер ${env.CT_IP}"
                    ssh -o StrictHostKeyChecking=no root@${env.PROX4} '
                        set -e
                        pct stop ${env.CT_ID}
                    '
                """
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
                } else {
                    echo "Директория с логами не существует, архивация пропущена"
                }
            }
            sh 'curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="❌ Ошибка при сборке $BUILD_ID проект $JOB_NAME подробнее: $BUILD_URL"'

                sh label: 'Выключить контейнер', script: """
                    echo "Выключаем контейнер ${env.CT_IP}"
                    ssh -o StrictHostKeyChecking=no root@${env.PROX4} '
                        set -e
                        pct stop ${env.CT_ID}
                    '
                """
        }
    }
}
```

## Шаг 3: Проверка путей
- **Allure results**: Убедитесь, что в контейнере результаты действительно сохраняются в `/root/ansible-proj/runtel_auto_tests/test_results/allure-results/`. Если путь другой, исправьте в команде scp.
- **Логи**: Если логи сохраняются в другом месте, исправьте путь.

## Шаг 4: Установка Allure plugin в Jenkins
Убедитесь, что в Jenkins установлен плагин "Allure Jenkins Plugin". Если нет, установите его через Manage Jenkins → Plugins.

## Шаг 5: Тестирование
Запустите сборку и проверьте:
1. Копируются ли результаты из контейнера.
2. Генерируется ли Allure отчёт.
3. Архивируются ли логи.
4. Приходят ли уведомления в Telegram.

## Примечания
- Если вы не используете Telegram, удалите соответствующие блоки.
- Если логи не нужны, удалите архивцию.
- Если Allure отчёт не требуется, удалите блок `allure`.

После этих изменений ваш pipeline будет генерировать Allure отчёты и архивировать логи аналогично проекту `run_auto_tests`.