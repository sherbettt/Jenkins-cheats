# Рефакторинг stage 'Test' в JenkinsFile_auto_tests

## Текущая структура (громоздкая if-else)

```groovy
stage('Test') {
    steps {
        script {
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
            // Выбираем шаг в зависимости от значения параметра SUITE
            def suiteValue = env.SUITE ?: "regression (all tests)"
            if (suiteValue == "regression (all tests)") {
                sh label: 'Run all tests', script: """
                    set -eux
                    cd ${env.WORKSPACE}/auto_tests/
                    
                    echo "Устанавливаем зависимости"
                    /home/tests_venv/bin/pip3 install -r requirements.txt
                    
                    echo "Общее количество файлов с тестами:"
                    find ./tests/api_tests -name 'test_*.py' | wc -l

                    echo "Сбор информации о тестах pytest:"
                    /home/tests_venv/bin/python -m pytest ./tests/api_tests/ -c vars/pyproject-auto_tests.toml --collect-only -q
                    
                    echo "Запускаем тесты (all)"
                    /home/tests_venv/bin/python -m pytest ./tests/api_tests/ -c vars/pyproject-auto_tests.toml

                    #Проверяем наличие Allure отчета
                    echo "Check Allure report"
                    echo "Проверяем сгенерированный allure репорт"
                    ls -alFh ${env.WORKSPACE}/auto_tests/test_results/run_auto_tests || exit 0
                    ls -alFSh ${env.WORKSPACE}/auto_tests/test_results/run_auto_tests/allure-results || exit 0
                """
            } else if (suiteValue == "smoke (severities=blocker, critical)") {
                sh label: 'Run smoke tests', script: """
                    set -eux
                    cd ${env.WORKSPACE}/auto_tests/
                    
                    echo "Добавляем опцию для фильтрации тестов по severity"
                    sed -i '5a\\    "--allure-severities=blocker,critical",' vars/pyproject-auto_tests.toml
                    cat -n vars/pyproject-auto_tests.toml || exit 0
                    
                    echo "Устанавливаем зависимости"
                    /home/tests_venv/bin/pip3 install -r requirements.txt
                    
                    echo "Общее количество файлов с тестами:"
                    find ./tests/api_tests -name 'test_*.py' | wc -l

                    echo "Сбор информации о тестах pytest с фильтрацией по severity:"
                    /home/tests_venv/bin/python -m pytest -c vars/pyproject-auto_tests.toml ./tests/api_tests/ --collect-only -q
                    
                    echo "Запускаем тесты (critical)"
                    /home/tests_venv/bin/python -m pytest ./tests/api_tests/ -c vars/pyproject-auto_tests.toml

                    echo "Проверяем сгенерированный allure репорт"
                    ls -alFh ${env.WORKSPACE}/auto_tests/test_results/run_auto_tests || exit 0
                    ls -alFSh ${env.WORKSPACE}/auto_tests/test_results/run_auto_tests/allure-results || exit 0

                    echo "Смотри архив на мастер ноде 192.168.87.11 (jenkins-updated)"
                    echo "Путь /var/lib/jenkins/jobs/run_auto_tests/builds/<build_number>/archive/"
                """
            }
        }
    }
}
```

## Предлагаемый рефакторинг (единый shell-скрипт)

```groovy
stage('Test') {
    steps {
        script {
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
            
            // Единый скрипт для всех типов тестов
            sh label: 'Run tests based on SUITE parameter', script: """
                set -eux
                cd ${env.WORKSPACE}/auto_tests/
                
                # Определяем дополнительные аргументы pytest на основе SUITE
                EXTRA_PYTEST_ARGS=""
                if [ "\${SUITE}" = "smoke (severities=blocker, critical)" ]; then
                    echo "SUITE=smoke: добавляем фильтрацию по severity"
                    EXTRA_PYTEST_ARGS="--allure-severities=blocker,critical"
                else
                    echo "SUITE=regression: запускаем все тесты"
                fi
                
                echo "Устанавливаем зависимости"
                /home/tests_venv/bin/pip3 install -r requirements.txt
                
                echo "Общее количество файлов с тестами:"
                find ./tests/api_tests -name 'test_*.py' | wc -l

                echo "Сбор информации о тестах pytest:"
                /home/tests_venv/bin/python -m pytest ./tests/api_tests/ -c vars/pyproject-auto_tests.toml \${EXTRA_PYTEST_ARGS} --collect-only -q
                
                echo "Запускаем тесты"
                /home/tests_venv/bin/python -m pytest ./tests/api_tests/ -c vars/pyproject-auto_tests.toml \${EXTRA_PYTEST_ARGS}

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

## Ключевые изменения

1. **Убрана if-else конструкция Groovy** - вместо двух отдельных `sh` блоков используется один
2. **Логика перемещена в shell** - проверка значения SUITE происходит внутри bash-скрипта
3. **Убрана модификация pyproject.toml** - вместо sed используется передача параметра `--allure-severities` напрямую в pytest
4. **Переменная `EXTRA_PYTEST_ARGS`** - динамически формирует дополнительные аргументы для pytest
5. **Сохраняется вся остальная логика** - установка зависимостей, сбор информации, проверка отчетов

## Преимущества

- **Проще читать и поддерживать** - один скрипт вместо двух почти идентичных
- **Не модифицирует конфигурационные файлы** - избегаем потенциальных ошибок с sed
- **Более гибко** - легко добавить новые типы тестов (просто добавить условие в bash)
- **Соответствует принципу DRY** - избегаем дублирования кода

## Альтернативный вариант (вынесенный скрипт)

Если скрипт становится слишком большим, можно вынести его в отдельный файл:

```groovy
stage('Test') {
    steps {
        script {
            // ... подготовительные шаги ...
            
            sh label: 'Run tests', script: """
                cd ${env.WORKSPACE}/auto_tests/
                ./scripts/run_tests.sh "\${SUITE}"
            """
        }
    }
}
```

Где `scripts/run_tests.sh` содержит всю логику проверки SUITE и запуска pytest.