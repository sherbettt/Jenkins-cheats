# Размещение environment.properties для Allure

## Ответ на вопрос

**Где добавить stage 'Add environment info'?**

Stage 'Add environment info' нужно добавить **ПЕРЕД генерацией Allure отчёта**, но **ПОСЛЕ копирования allure-results из контейнера**.

### Оптимальное расположение:

1. **После stage 'Тестирование ЛК'** (где копируются allure-results)
2. **Перед post-блоком** (где выполняется генерация отчёта)

### Почему так:
- `environment.properties` должен находиться в директории `allure-results/`
- Allure плагин читает эту директорию при генерации отчёта
- Если добавить в post-блок после `allure()`, будет поздно - отчёт уже сгенерирован

## Конкретное предложение для Jenkinsfile

### Текущая структура:
```groovy
stage('Тестирование ЛК') {
    steps {
        script {
            def suiteValue = env.SUITE ?: "regression (all tests)"
            build.testLK(env.CT_IP, suiteValue)  // Здесь копируются allure-results
        }
    }
}

// После этого добавить:
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
                Project=${env.PROJECT_NAME}
            """
            
            // Проверяем создание файла
            sh 'cat allure-results/environment.properties'
        }
    }
}
```

## Альтернативный вариант: Добавить в функцию testLK

Если хотите централизовать логику, можно модифицировать функцию `testLK` в `build.groovy`:

### В build.groovy:
```groovy
def testLK(containerIP, suite) {
    sh label: 'Test LK', script: """
        ssh -o StrictHostKeyChecking=no root@${containerIP} '
            # ... существующий код тестов ...
        '
        # Копируем результаты из контейнера
        mkdir -p allure-results
        scp -o StrictHostKeyChecking=no -r root@${containerIP}:/root/ansible-proj/runtel_auto_tests/test_results/allure-results/* allure-results/ 2>/dev/null || echo "Результаты Allure не найдены"
        
        # Создаём environment.properties
        cat > allure-results/environment.properties << EOF
        Jenkins Job=${env.JOB_NAME}
        Build Number=${env.BUILD_NUMBER}
        Suite=${suite}
        Date=$(date)
        Container IP=${containerIP}
        EOF
    """
}
```

## Проверка правильности размещения

### Правильный порядок stages:
1. `Тестирование ЛК` - выполняет тесты и копирует allure-results
2. `Prepare Allure Environment` - добавляет environment.properties
3. `SonarQube Analysis` - (если есть)
4. `post { success { allure(...) } }` - генерация отчёта

### Неправильный порядок:
- Добавление environment.properties **после** allure() - не сработает
- Добавление **до** копирования allure-results - файл будет перезаписан

## Дополнительные улучшения

### 1. Очистка старых результатов
```groovy
stage('Clean Allure Results') {
    steps {
        sh 'rm -rf allure-results/* allure-report/* || true'
    }
}
```
**Размещение**: Перед stage 'Тестирование ЛК'

### 2. Добавление категорий тестов
Создать файл `allure-results/categories.json`:
```json
[
  {
    "name": "Smoke tests",
    "matchedStatuses": ["passed", "failed"]
  }
]
```

### 3. Добавление custom labels
В environment.properties можно добавить больше информации:
```properties
version=2.22.5
environment=production
branch=${env.gitlabSourceBranch}
commit=${env.gitlabMergeCommitSha}
```

## Тестирование

После добавления stage:
1. **Запустите сборку**
2. **Проверьте файл** `allure-results/environment.properties` в workspace
3. **Откройте Allure Report** и найдите раздел "Environment"
4. **Убедитесь**, что информация отображается корректно

## Пример полного stage

```groovy
stage('Prepare Allure Environment') {
    steps {
        script {
            // Убедимся, что директория существует
            sh 'mkdir -p allure-results'
            
            // Создаём environment.properties
            writeFile file: 'allure-results/environment.properties', text: """
                Jenkins Job=${env.JOB_NAME}
                Build Number=${env.BUILD_NUMBER}
                Build URL=${env.BUILD_URL}
                Suite=${params.SUITE}
                Date=${new Date()}
                Container IP=${env.CT_IP}
                Project=${env.PROJECT_NAME}
                Node=${env.NODE_NAME}
                Workspace=${env.WORKSPACE}
            """
            
            // Добавляем categories.json для группировки тестов
            writeFile file: 'allure-results/categories.json', text: '''[
                {
                    "name": "Smoke tests",
                    "matchedStatuses": ["passed", "failed"],
                    "messageRegex": ".*smoke.*"
                },
                {
                    "name": "Regression tests",
                    "matchedStatuses": ["passed", "failed"]
                }
            ]'''
            
            // Логируем созданные файлы
            sh 'ls -la allure-results/'
            sh 'cat allure-results/environment.properties'
        }
    }
}
```

## Заключение

**Рекомендую добавить отдельный stage** 'Prepare Allure Environment' после 'Тестирование ЛК'. Это:
- Делает pipeline более читаемым
- Позволяет легко добавлять другие файлы для Allure
- Упрощает отладку