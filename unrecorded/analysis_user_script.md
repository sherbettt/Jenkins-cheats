# Анализ варианта пользователя

## Предложенный пользователем скрипт

```bash
sh label: 'Run tests based on SUITE parameter', script: """
    set -eux
    cd ${env.WORKSPACE}/auto_tests/
    
    echo "Устанавливаем зависимости"
    /home/tests_venv/bin/pip3 install -r requirements.txt
    
    echo "Общее количество файлов с тестами:"
    find ./tests/api_tests -name 'test_*.py' | wc -l

    echo "Сбор информации о тестах pytest:"
    /home/tests_venv/bin/python -m pytest ./tests/api_tests/ -c vars/pyproject-auto_tests.toml --collect-only -q
    

    if echo "\${suiteValue}" | grep -q "smoke"; then
        echo "Run smoke tests (severities=blocker, critical)"
        #sed -i -e '5a\\' -e '    \"--allure-severities=blocker,critical\",' pyproject.toml
        /home/tests_venv/bin/python -m pytest ./tests/api_tests/ -c vars/pyproject-auto_tests.toml -v -s --allure-severities=blocker,critical
    else
        echo "Run all tests"
        /home/tests_venv/bin/python -m pytest ./tests/api_tests/ -c vars/pyproject-auto_tests.toml -v -s
    fi


    echo "Запускаем тесты (all)"
    /home/tests_venv/bin/python -m pytest ./tests/api_tests/ -c vars/pyproject-auto_tests.toml

    #Проверяем наличие Allure отчета
    echo "Check Allure report"
    echo "Проверяем сгенерированный allure репорт"
    ls -alFh ${env.WORKSPACE}/auto_tests/test_results/run_auto_tests || exit 0
    ls -alFSh ${env.WORKSPACE}/auto_tests/test_results/run_auto_tests/allure-results || exit 0
"""
```

## Проблемы в текущем варианте

### 1. Дублирование запуска pytest
В скрипте есть два запуска pytest:
- Первый внутри if-else (строки с `if echo "\${suiteValue}"...`)
- Второй после if-else (`echo "Запускаем тесты (all)"`)

Это означает, что тесты будут запущены дважды, что:
- Удваивает время выполнения
- Может привести к конфликтам (например, если тесты создают временные файлы)
- Генерирует дублирующиеся allure-результаты

### 2. Переменная `suiteValue` не определена в shell
В shell-скрипте используется `\${suiteValue}`, но эта переменная определена только в Groovy контексте (строка 304: `def suiteValue = env.SUITE ?: "regression (all tests)"`). В shell она будет пустой, если не передать явно.

Нужно либо:
- Использовать `\${SUITE}` (переменная окружения Jenkins)
- Или передать `suiteValue` как параметр

### 3. Отсутствие подготовительных шагов
В оригинальном Jenkinsfile есть важные подготовительные шаги:
- `Check pyproject-*.toml files`
- `Restore from pyproject-*.toml from bkp file`

Эти шаги отсутствуют в предложенном скрипте, что может привести к проблемам с конфигурацией.

### 4. Проверка через grep может быть менее надёжной
`echo "\${suiteValue}" | grep -q "smoke"` проверяет наличие подстроки "smoke". Это работает для текущих значений параметра, но если в будущем добавятся значения типа "smoke-special", они тоже будут распознаны как smoke. Это может быть как преимуществом, так и недостатком.

### 5. Разные параметры pytest
В if-else используются параметры `-v -s`, а в дублирующем запуске - без них. Это создаёт неконсистентность.

## Улучшенная версия (исправляющая проблемы)

```groovy
stage('Test') {
    steps {
        script {
            // Подготовительные шаги (оставляем из оригинала)
            sh label: 'Passing variables to utils/logger.py', script: '''
                set -eux
                echo 'Экспорт переменных в OS'
                echo 'В файле utils/logger.py смотри import os'
                export JENKINS_WORKSPACE="$WORKSPACE"
                export JENKINS_JOB_NAME="$JOB_NAME"
            '''
            sh label: 'Check pyproject-*.toml files', script: """
                ls -alFh ${env.WORKSPACE}/auto_tests/vars/pyproject-auto_tests.toml || exit 0
                cat -n ${env.WORKSPACE}/auto_tests/vars/pyproject-auto_tests.toml || exit 0
            """
            sh label: 'Restore from pyproject-*.toml from bkp file', script: """
                cd ${env.WORKSPACE}/auto_tests/vars
                cp pyproject-auto_tests.toml.bkp pyproject-auto_tests.toml
                cat -n pyproject-auto_tests.toml || exit 0
            """
            
            // Единый скрипт с исправлениями
            sh label: 'Run tests based on SUITE parameter', script: """
                set -eux
                cd ${env.WORKSPACE}/auto_tests/
                
                echo "Устанавливаем зависимости"
                /home/tests_venv/bin/pip3 install -r requirements.txt
                
                echo "Общее количество файлов с тестами:"
                find ./tests/api_tests -name 'test_*.py' | wc -l

                echo "Сбор информации о тестах pytest:"
                /home/tests_venv/bin/python -m pytest ./tests/api_tests/ -c vars/pyproject-auto_tests.toml --collect-only -q
                
                # Определяем дополнительные аргументы на основе SUITE
                # Используем переменную окружения Jenkins SUITE
                EXTRA_ARGS=""
                if echo "\${SUITE}" | grep -q "smoke"; then
                    echo "SUITE содержит 'smoke': запускаем smoke-тесты"
                    EXTRA_ARGS="--allure-severities=blocker,critical"
                else
                    echo "SUITE не содержит 'smoke': запускаем все тесты"
                fi
                
                echo "Запускаем тесты с параметрами: \${EXTRA_ARGS}"
                /home/tests_venv/bin/python -m pytest ./tests/api_tests/ -c vars/pyproject-auto_tests.toml -v -s \${EXTRA_ARGS}

                # Проверяем наличие Allure отчета
                echo "Check Allure report"
                echo "Проверяем сгенерированный allure репорт"
                ls -alFh ${env.WORKSPACE}/auto_tests/test_results/run_auto_tests || exit 0
                ls -alFSh ${env.WORKSPACE}/auto_tests/test_results/run_auto_tests/allure-results || exit 0
            """
        }
    }
}
```

## Ключевые улучшения

1. **Убрано дублирование** - только один запуск pytest
2. **Исправлена переменная** - используем `\${SUITE}` (переменная окружения Jenkins)
3. **Сохранены подготовительные шаги** - остаются отдельными sh-блоками для ясности
4. **Консистентные параметры** - всегда используем `-v -s`
5. **Чистая логика** - используем переменную `EXTRA_ARGS` для накопления дополнительных параметров

## Сравнение подходов

| Аспект | Оригинальный if-else | Ваш вариант | Улучшенный вариант |
|--------|---------------------|-------------|-------------------|
| Читаемость | Низкая (громоздко) | Средняя | Высокая |
| Дублирование кода | Высокое | Среднее (есть дубль pytest) | Низкое |
| Надёжность | Высокая | Средняя (проблемы с переменными) | Высокая |
| Поддержка | Сложная | Проще | Простая |
| Гибкость | Низкая (жёсткая структура) | Средняя | Высокая |

## Рекомендация

Использовать **улучшенный вариант**, так как он:
- Решает все выявленные проблемы
- Сохраняет преимущества вашего подхода (единый скрипт)
- Легко читается и поддерживается
- Не содержит скрытых ошибок

Если хотите сохранить точную логику оригинального Jenkinsfile (с модификацией pyproject.toml через sed), можно адаптировать скрипт соответствующим образом.