# Правила синтаксиса для SSH команд в Jenkinsfile

## Основные проблемы и решения

### 1. Экранирование знака доллара `$`

**Проблема**: В Groovy строках с тройными кавычками `"""` знак `$` интерпретируется как начало Groovy-переменной.

**Решение**:
- **Bash переменные**: экранировать как `\$`
- **Jenkins переменные**: не экранировать, использовать `${VAR}`

**Пример**:
```groovy
// НЕПРАВИЛЬНО
sh """
    ssh user@host '
        VAR=$BASH_VAR      # Ошибка!
        echo $PATH         # Ошибка!
    '
"""

// ПРАВИЛЬНО
sh """
    ssh user@host '
        VAR=\\$BASH_VAR    # Экранировано
        echo \$PATH        # Экранировано
        echo ${JENKINS_VAR} # Jenkins переменная
    '
"""
```

### 2. Использование кавычек

**Проблема**: Вложенные кавычки вызывают синтаксические ошибки.

**Решение**: Использовать разные типы кавычек:
- Внешние: тройные кавычки `"""` для Groovy
- Средние: одинарные кавычки `'` для SSH команды  
- Внутренние: двойные кавычки `"` для bash строк

**Пример**:
```groovy
sh """
    ssh user@host '
        # Внутри SSH используем двойные кавычки для bash
        echo "Hello world"
        VAR="value"
        
        # Если нужны одинарные кавычки внутри - экранировать
        echo 'It\\'s working'
    '
"""
```

### 3. Передача Jenkins переменных

**Проблема**: Jenkins переменные не подставляются внутри SSH команды.

**Решение**: Подставлять переменные ДО отправки SSH команды:

```groovy
// ПРАВИЛЬНО - переменная подставляется Jenkins
sh """
    ssh user@host '
        echo "Branch: ${env.gitlabSourceBranch}"
        echo "Job: ${env.JOB_NAME}"
    '
"""

// Альтернатива: определить переменную перед SSH
script {
    def targetBranch = env.gitlabSourceBranch ?: 'master'
    sh """
        ssh user@host '
            echo "Branch: ${targetBranch}"
        '
    """
}
```

### 4. Многострочные команды

**Проблема**: Длинные команды трудно читать и отлаживать.

**Решение**: Использовать heredoc или разбивать на логические блоки:

```groovy
sh """
    ssh user@host << 'EOF'
        # Многострочная команда
        set -eux
        cd /path
        git fetch
        git checkout branch
        # ...
EOF
"""
```

Или использовать переменную:

```groovy
script {
    def cmd = """
        set -eux
        cd /path
        git fetch
        git checkout branch
    """
    
    sh """
        ssh user@host '${cmd}'
    """
}
```

## Шаблоны для часто используемых конструкций

### 1. Базовый SSH вызов
```groovy
sh """
    ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=10 \
        root@${env.CT_IP} '
            set -eux  # Включить отладку
            cd ${env.AT_SPACE}
            # Команды
        '
"""
```

### 2. SSH с передачей переменных окружения
```groovy
sh """
    ssh -o StrictHostKeyChecking=no root@${env.CT_IP} "
        export JENKINS_JOB_NAME='${env.JOB_NAME}'
        export JENKINS_BUILD_NUMBER='${env.BUILD_NUMBER}'
        export SUITE='${params.SUITE}'
        
        cd ${env.AT_SPACE}
        # Команды с переменными
    "
"""
```

### 3. Копирование файлов на контейнер
```groovy
sh """
    # Копируем файл
    scp -o StrictHostKeyChecking=no \
        ${LOCAL_FILE} \
        root@${env.CT_IP}:${REMOTE_PATH}
    
    # Проверяем
    ssh -o StrictHostKeyChecking=no root@${env.CT_IP} "
        ls -la ${REMOTE_PATH}
    "
"""
```

### 4. Выполнение команды с возвратом результата
```groovy
script {
    def result = sh(
        script: """
            ssh -o StrictHostKeyChecking=no root@${env.CT_IP} '
                command
                echo \$?  # Возвращаем код выхода
            '
        """,
        returnStdout: true
    ).trim()
    
    echo "Result: ${result}"
}
```

## Распространенные ошибки и их исправление

### Ошибка 1: `illegal string body character after dollar sign`
```groovy
// ОШИБКА
sh """
    echo "Cost: $100"
"""

// ИСПРАВЛЕНИЕ
sh """
    echo "Cost: \$100"  # Экранировать $
"""
```

### Ошибка 2: Неподставляются переменные
```groovy
// ОШИБКА: переменная внутри одинарных кавычек
sh '''
    echo ${JOB_NAME}  # Не подставится
'''

// ИСПРАВЛЕНИЕ: использовать двойные кавычки
sh """
    echo ${env.JOB_NAME}  # Подставится
"""
```

### Ошибка 3: Проблемы с кавычками
```groovy
// ОШИБКА
sh """
    ssh host 'echo "It's broken"'
"""

// ИСПРАВЛЕНИЕ
sh """
    ssh host 'echo "It\\'s working"'
"""
```

## Best Practices

### 1. Всегда использовать `set -eux` в SSH командах
```groovy
ssh user@host '
    set -eux  # -e: exit on error, -u: treat unset vars as error, -x: print commands
    # Команды
'
```

### 2. Проверять подключение перед выполнением команд
```groovy
stage('Test SSH connection') {
    steps {
        sh """
            ssh -o StrictHostKeyChecking=no \
                -o ConnectTimeout=5 \
                root@${env.CT_IP} "hostname" || {
                echo "SSH connection failed"
                exit 1
            }
        """
    }
}
```

### 3. Использовать временные файлы для сложных команд
```groovy
script {
    writeFile(
        file: "${env.WORKSPACE}/script.sh",
        text: """
            #!/bin/bash
            set -eux
            complex_command_1
            complex_command_2
        """
    )
    
    sh """
        scp ${env.WORKSPACE}/script.sh root@${env.CT_IP}:/tmp/
        ssh root@${env.CT_IP} "bash /tmp/script.sh"
    """
}
```

### 4. Логировать выполняемые команды
```groovy
sh """
    echo "Executing on ${env.CT_IP}:"
    echo "Command: cd ${env.AT_SPACE} && git status"
    
    ssh root@${env.CT_IP} '
        echo "=== Starting command ==="
        cd ${env.AT_SPACE}
        git status
        echo "=== Command completed ==="
    '
"""
```

## Пример полного stage с SSH

```groovy
stage('Execute on Container') {
    steps {
        script {
            // 1. Определяем переменные
            def targetBranch = env.gitlabSourceBranch ?: 'master'
            
            // 2. Выполняем команду
            sh label: 'Run git operations on container', script: """
                # Логируем начало
                echo "=== Executing on ${env.CT_IP} ==="
                echo "Path: ${env.AT_SPACE}"
                echo "Branch: ${targetBranch}"
                
                # SSH команда
                ssh -o StrictHostKeyChecking=no root@${env.CT_IP} '
                    set -eux
                    cd ${env.AT_SPACE}
                    
                    # Git операции
                    git fetch --all --prune
                    
                    if git ls-remote --heads origin ${targetBranch} | grep -q ${targetBranch}; then
                        git checkout -f ${targetBranch}
                        git reset --hard origin/${targetBranch}
                    else
                        git checkout -f master
                        git reset --hard origin/master
                    fi
                    
                    # Результат
                    git log -1 --oneline
                    echo "=== Success ==="
                '
                
                # Логируем завершение
                echo "=== Command completed ==="
            """
            
            // 3. Обработка ошибок
            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                // Дополнительные проверки
            }
        }
    }
}
```

## Проверка синтаксиса

Перед запуском пайплайна проверьте:
1. Все `$` для bash переменных экранированы как `\$`
2. Jenkins переменные используют правильный синтаксис `${env.VAR}`
3. Кавычки правильно вложены
4. Нет синтаксических ошибок Groovy