# Анализ предложенного кода очистки Allure результатов

## Предложенный код
```groovy
stage('Тестирование ЛК') {
    steps {
        echo "Очистка старых результатов Allure тестов"
        sh 'rm -rf allure-results/* allure-report/* || true'
        script {
            def suiteValue = env.SUITE ?: "regression (all tests)"
            build.testLK(env.CT_IP, suiteValue)
        }
    }
}
```

## Оценка корректности

### Положительные стороны:
1. **Очистка перед тестами** - правильный подход, предотвращает накопление старых результатов
2. **Использование `|| true`** - предотвращает падение пайплайна если директории не существуют
3. **Логирование** - echo сообщение поясняет действие

### Потенциальные проблемы:
1. **Очистка внутри того же stage** - может быть неочевидно при чтении логов
2. **Очистка allure-report** - не обязательно, так как он создаётся заново в post-блоке, но безопасно
3. **Если testLK копирует результаты в поддиректории** - очистка `allure-results/*` удалит всё, включая возможные нужные поддиректории

## Рекомендуемая структура

### Вариант 1: Отдельный stage для очистки (более читаемо)
```groovy
stage('Clean Allure Results') {
    steps {
        echo "Очистка старых результатов Allure тестов"
        sh '''
            rm -rf allure-results/* || true
            rm -rf allure-report/* || true
        '''
    }
}

stage('Тестирование ЛК') {
    steps {
        script {
            def suiteValue = env.SUITE ?: "regression (all tests)"
            build.testLK(env.CT_IP, suiteValue)
        }
    }
}

stage('Prepare Allure Environment') {
    steps {
        script {
            // Создаём environment.properties
            writeFile file: 'allure-results/environment.properties', text: """
                Jenkins Job=${env.JOB_NAME}
                Build Number=${env.BUILD_NUMBER}
                Suite=${params.SUITE}
                Date=${new Date()}
                Container IP=${env.CT_IP}
            """
        }
    }
}
```

### Вариант 2: Оставить как есть, но улучшить (компактно)
```groovy
stage('Тестирование ЛК') {
    steps {
        script {
            // Очистка перед тестами
            sh '''
                echo "Очистка старых результатов Allure тестов"
                rm -rf allure-results/* allure-report/* 2>/dev/null || true
            '''
            
            // Запуск тестов
            def suiteValue = env.SUITE ?: "regression (all tests)"
            build.testLK(env.CT_IP, suiteValue)
            
            // Добавление environment info
            writeFile file: 'allure-results/environment.properties', text: """
                Jenkins Job=${env.JOB_NAME}
                Build Number=${env.BUILD_NUMBER}
                Suite=${suiteValue}
                Date=${new Date()}
                Container IP=${env.CT_IP}
            """
        }
    }
}
```

## Проверка функции testLK

Убедитесь, что функция `testLK` в `build.groovy`:
1. Копирует результаты в `allure-results/` (а не в поддиректорию)
2. Не зависит от существующих файлов в `allure-results/`

Если testLK создаёт поддиректории (например, `allure-results/container-800/`), то очистка `allure-results/*` удалит эту поддиректорию после копирования. В этом случае лучше очищать до testLK, но не после.

## Итоговая рекомендация

**Предложенный код правильный**, но для улучшения читаемости и поддержки рекомендую:

1. **Использовать Вариант 1** с отдельными stages
2. **Добавить stage 'Prepare Allure Environment'** для environment.properties
3. **Проверить логи** после запуска, чтобы убедиться, что:
   - Очистка выполняется
   - testLK копирует результаты
   - environment.properties создаётся
   - Allure отчёт генерируется с новой информацией

## Тестирование

После внесения изменений:
1. Запустите сборку
2. Проверьте, что в логах есть "Очистка старых результатов Allure тестов"
3. Убедитесь, что `allure-results/` не пустой после testLK
4. Проверьте наличие `allure-results/environment.properties`
5. Откройте Allure Report и найдите раздел "Environment"