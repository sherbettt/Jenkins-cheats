# Исправление ошибки в Jenkinsfile

## Ошибка
```
WorkflowScript: 225: Expected a step @ line 225, column 17.
 def durationMin = currentBuild.duration / 60000
 ^
```

## Причина
В Declarative Pipeline внутри `post { failure { ... } }` можно использовать только **steps**, но не голые Groovy выражения. Строки `def durationMin = ...` и `def durationMinRounded = ...` - это Groovy выражения, а не steps.

## Неправильный код
```groovy
post {
    failure {
        withCredentials([...]) {
            allure([...])
            // ...
            sh 'curl ...'
            
            // ОШИБКА: голые Groovy выражения вне script {}
            def durationMin = currentBuild.duration / 60000
            def durationMinRounded = String.format("%.2f", durationMin)
            echo "Длительность сборки: ${durationMinRounded} min"
            
            script {
                def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: ${currentBuild.duration} ms = ${durationMinRounded} min"
                notify.TGNotify("deb12:$message")
            }
        }
    }
}
```

## Исправленный код

### Вариант 1: Переместить всё в один script блок
```groovy
post {
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
                // Вычисления внутри script блока
                def durationMin = currentBuild.duration / 60000
                def durationMinRounded = String.format("%.2f", durationMin)
                echo "Длительность сборки: ${durationMinRounded} min"
                
                // Telegram уведомление
                def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: ${durationMinRounded} мин"
                notify.TGNotify("deb12:$message")
                
                // curl также можно переместить сюда, если нужно
                sh 'curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="❌ Ошибка при сборке $BUILD_ID проект $JOB_NAME подробнее: $BUILD_URL"'
            }
        }
    }
}
```

### Вариант 2: Оставить curl вне script, но вычисления внутри
```groovy
post {
    failure {
        withCredentials([
            string(credentialsId: 'TGbotSecret', variable: 'TOKEN'),
            string(credentialsId: 'TGChatID', variable: 'CHAT_ID')
        ]) {
            allure([...])
            
            // curl остаётся как step
            sh 'curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="❌ Ошибка при сборке $BUILD_ID проект $JOB_NAME подробнее: $BUILD_URL"'
            
            script {
                // Вычисления внутри script блока
                def durationMin = currentBuild.duration / 60000
                def durationMinRounded = String.format("%.2f", durationMin)
                echo "Длительность сборки: ${durationMinRounded} min"
                
                // Дополнительное Telegram уведомление через notify
                def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: ${durationMinRounded} мин"
                notify.TGNotify("deb12:$message")
            }
        }
    }
}
```

### Вариант 3: Компактный (рекомендуемый)
```groovy
post {
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
                // Вычисление длительности
                def durationMin = currentBuild.duration / 60000.0
                def durationMinRounded = String.format("%.2f", durationMin)
                
                // Логирование
                echo "Длительность сборки: ${durationMinRounded} мин"
                
                // Два уведомления (curl и TGNotify)
                sh 'curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="❌ Ошибка при сборке $BUILD_ID проект $JOB_NAME подробнее: $BUILD_URL"'
                
                def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: ${durationMinRounded} мин"
                notify.TGNotify("deb12:$message")
            }
        }
    }
}
```

## Почему это работает

1. **`script {}`** - специальный step в Declarative Pipeline, который позволяет выполнять произвольный Groovy код
2. Внутри `script {}` можно использовать переменные, вычисления, циклы и т.д.
3. Вне `script {}` можно использовать только predefined steps (`echo`, `sh`, `allure`, `withCredentials` и т.д.)

## Дополнительное улучшение

Можно вынести вычисление длительности в функцию для повторного использования:

```groovy
// В начале Jenkinsfile (после pipeline {)
def formatDuration(durationMs) {
    def durationMin = durationMs / 60000.0
    return String.format("%.2f", durationMin)
}

// Затем в post блоке
post {
    failure {
        script {
            def durationText = formatDuration(currentBuild.duration)
            // ...
        }
    }
}
```

Но в Declarative Pipeline функции нужно определять особым образом (обычно в shared library или в `environment`).

## Проверка исправления

После внесения изменений:
1. Сохраните Jenkinsfile
2. Запустите сборку
3. Если сборка завершится ошибкой, проверьте:
   - Нет ли ошибки "Expected a step"
   - Работает ли вычисление длительности
   - Отправляются ли Telegram уведомления