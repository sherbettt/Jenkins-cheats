# Решения проблемы с установкой Allure Commandline в Jenkins

## Проблема
Ошибка при выполнении post блока Jenkins:
```
java.io.IOException: Failed to install https://repo1.maven.org/maven2/io/qameta/allure/allure-commandline/2.34.0/allure-commandline-2.34.0.zip
```

## Причины
1. **Нет сетевого доступа к repo1.maven.org** - Jenkins не может скачать архив
2. **Прокси-настройки** - Jenkins настроен через прокси, который блокирует загрузку
3. **Дисковое пространство** - недостаточно места в `/var/lib/jenkins/tools/`
4. **Права доступа** - у пользователя Jenkins нет прав на запись в директорию tools
5. **Устаревший плагин Allure** - версия плагина несовместима

## Решения

### 1. Проверка сетевого доступа
Выполнить команду на Jenkins master для проверки доступа:
```bash
curl -I https://repo1.maven.org/maven2/io/qameta/allure/allure-commandline/2.34.0/allure-commandline-2.34.0.zip
wget https://repo1.maven.org/maven2/io/qameta/allure/allure-commandline/2.38.1/allure-commandline-2.38.1.zip
```

### 2. Ручная установка Allure Commandline
#### Вариант A: Установка через Jenkins UI
1. Перейти в `Manage Jenkins` → `Global Tool Configuration`
2. Найти "Allure Commandline"
3. Добавить новую установку с указанием пути к уже установленному Allure
4. Или изменить URL на зеркало (например, GitHub Releases)

#### Вариант B: Установка вручную на файловую систему
```bash
# На Jenkins master
cd /var/lib/jenkins/tools/ru.yandex.qatools.allure.jenkins.tools.AllureCommandlineInstallation/
mkdir -p main
cd main
wget https://github.com/allure-framework/allure2/releases/download/2.34.0/allure-2.34.0.tgz
tar -xzf allure-2.34.0.tgz
mv allure-2.34.0/* .
rm -rf allure-2.34.0 allure-2.34.0.tgz
```

### 3. Изменение конфигурации Jenkinsfile
#### Вариант A: Отключить автоматическую загрузку Allure
Добавить параметр `disableAutoDownload: true` в конфигурацию allure:
```groovy
allure([
    includeProperties: false,
    jdk: '',
    report: 'allure-report/',
    results: [[path: 'allure-results/']],
    disableAutoDownload: true  // Отключаем автоматическую загрузку
])
```

#### Вариант B: Использовать уже установленный Allure
Указать путь к Allure в переменной окружения:
```groovy
environment {
    ALLURE_HOME = '/usr/local/bin/allure'
}
```

### 4. Альтернатива: Генерация отчёта через shell
Вместо использования плагина Allure Jenkins, сгенерировать отчёт через shell-скрипт:
```groovy
post {
    success {
        script {
            // Генерация Allure отчёта вручную
            sh '''
                # Проверяем наличие allure
                if ! command -v allure &> /dev/null; then
                    echo "Устанавливаем allure"
                    wget https://github.com/allure-framework/allure2/releases/download/2.34.0/allure-2.34.0.tgz
                    tar -xzf allure-2.34.0.tgz
                    export PATH=$PWD/allure-2.34.0/bin:$PATH
                fi
                
                # Генерируем отчёт
                allure generate allure-results/ -o allure-report/ --clean
                
                # Архивируем отчёт
                archiveArtifacts artifacts: 'allure-report/**'
            '''
        }
    }
}
```

### 5. Временное решение: Пропустить генерацию Allure
Если отчёт не критичен, можно закомментировать блок allure:
```groovy
post {
    success {
        // allure([...])  // Закомментировать
        echo "Allure отчёт временно отключен из-за проблем с загрузкой"
    }
}
```

## Рекомендуемое решение

### Для быстрого исправления:
1. **Проверить доступ к Maven Central** с Jenkins master
2. **Если доступ есть** - перезапустить сборку (возможно, временная проблема сети)
3. **Если доступа нет** - использовать вариант 4 (генерация через shell)

### Для постоянного решения:
1. **Установить Allure вручную** на всех Jenkins agents
2. **Настроить Global Tool Configuration** в Jenkins
3. **Обновить Jenkinsfile** для использования локально установленного Allure

## Диагностические команды
```bash
# Проверка дискового пространства
df -h /var/lib/jenkins

# Проверка прав доступа
ls -la /var/lib/jenkins/tools/

# Проверка установленных версий Allure
ls -la /var/lib/jenkins/tools/ru.yandex.qatools.allure.jenkins.tools.AllureCommandlineInstallation/

# Проверка сетевого доступа
curl -v https://repo1.maven.org/maven2/io/qameta/allure/allure-commandline/2.34.0/allure-commandline-2.34.0.zip 2>&1 | head -20
```

## Если проблема в прокси
Настроить прокси в Jenkins:
1. `Manage Jenkins` → `Plugin Manager` → `Advanced`
2. Указать Proxy Server в разделе "HTTP Proxy Configuration"
3. Или добавить параметры JVM при запуске Jenkins:
```
-Dhttp.proxyHost=proxy.example.com -Dhttp.proxyPort=8080