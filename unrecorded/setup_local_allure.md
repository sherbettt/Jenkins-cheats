# Настройка локального Allure Commandline в Jenkins

## Текущее состояние
Пользователь скачал архивы Allure:
- `/root/programs/allure/allure-commandline/allure-commandline-2.34.0.zip`
- `/root/programs/allure/allure-commandline/allure-commandline-2.38.1.zip`

## Вариант 1: Установка в Jenkins Global Tools

### Шаг 1: Распаковка Allure
```bash
# На Jenkins master (или на ноде, где работает сборка)
cd /root/programs/allure/allure-commandline/
unzip allure-commandline-2.38.1.zip -d allure-2.38.1
# Или используйте более новую версию
```

### Шаг 2: Настройка в Jenkins UI
1. Перейдите в `Manage Jenkins` → `Global Tool Configuration`
2. Найдите раздел "Allure Commandline"
3. Добавьте новую установку:
   - Name: `allure-2.38.1`
   - Install automatically: **Снять галочку**
   - ALLURE_HOME: `/root/programs/allure/allure-commandline/allure-2.38.1`
4. Сохраните

### Шаг 3: Обновление Jenkinsfile
Убедитесь, что в Jenkinsfile используется правильное имя установки:
```groovy
allure([
    includeProperties: false,
    jdk: '',
    report: 'allure-report/',
    results: [[path: 'allure-results/']],
    commandline: 'allure-2.38.1'  // Указать имя установки
])
```

## Вариант 2: Использование локального пути без настройки Jenkins

### Шаг 1: Распаковка и настройка PATH
```bash
# Распаковать allure
cd /root/programs/allure/allure-commandline/
unzip -q allure-commandline-2.38.1.zip -d allure-2.38.1

# Создать симлинк в /usr/local/bin
ln -sf /root/programs/allure/allure-commandline/allure-2.38.1/bin/allure /usr/local/bin/allure

# Проверить
allure --version
```

### Шаг 2: Изменение Jenkinsfile для использования системного Allure
Добавить шаг генерации отчёта вручную:
```groovy
post {
    success {
        script {
            // Генерация Allure отчёта через системный allure
            sh '''
                # Проверяем наличие allure в системе
                if command -v allure &> /dev/null; then
                    echo "Генерируем Allure отчёт..."
                    allure generate allure-results/ -o allure-report/ --clean
                    
                    # Архивируем отчёт
                    archiveArtifacts artifacts: 'allure-report/**'
                else
                    echo "Allure не установлен в системе, отчёт не сгенерирован"
                fi
            '''
            
            // Остальной код (уведомления и т.д.)
            withCredentials([
                string(credentialsId: 'TGbotSecret', variable: 'TOKEN'),
                string(credentialsId: 'TGChatID', variable: 'CHAT_ID')
            ]) {
                sh 'curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id=${CHAT_ID} -d text="✅ Сборка $BUILD_ID Выполнена успешно проект $JOB_NAME подробнее: $BUILD_URL"'
            }
        }
    }
}
```

## Вариант 3: Установка в директорию Jenkins tools

### Шаг 1: Распаковать в правильную директорию Jenkins
```bash
# Определить директорию Jenkins tools
JENKINS_TOOLS_DIR="/var/lib/jenkins/tools/ru.yandex.qatools.allure.jenkins.tools.AllureCommandlineInstallation"

# Создать директорию для allure
mkdir -p $JENKINS_TOOLS_DIR/allure-2.38.1

# Распаковать архив
cd /root/programs/allure/allure-commandline/
unzip -q allure-commandline-2.38.1.zip -d $JENKINS_TOOLS_DIR/allure-2.38.1

# Установить правильные права
chown -R jenkins:jenkins $JENKINS_TOOLS_DIR/allure-2.38.1
```

### Шаг 2: Jenkins автоматически обнаружит установку
После этого Jenkins должен автоматически использовать эту установку, так как она находится в ожидаемой директории.

## Вариант 4: Самый простой - использовать уже скачанный архив

Если проблема только в загрузке с интернета, можно указать Jenkins использовать локальный файл:

### Шаг 1: Настроить Jenkins на использование локального файла
В конфигурации Allure Commandline в Jenkins:
- Установить "Install from Maven Central": **Нет**
- Выбрать "Install from file": указать путь `/root/programs/allure/allure-commandline/allure-commandline-2.38.1.zip`

## Проверка решения

После применения любого из вариантов, выполните тестовую сборку и проверьте:

1. **Логи Jenkins** - не должно быть ошибок загрузки Allure
2. **Allure отчёт** - должен быть сгенерирован в `allure-report/`
3. **Артефакты** - отчёт должен быть доступен для скачивания

## Если проблема persists

1. **Проверьте права доступа**:
   ```bash
   ls -la /var/lib/jenkins/tools/
   ps aux | grep jenkins
   ```

2. **Проверьте версию плагина Allure**:
   - Убедитесь, что плагин совместим с версией Jenkins
   - Рассмотрите обновление плагина

3. **Временное отключение Allure**:
   Если отчёт не критичен, можно закомментировать блок `allure()` в Jenkinsfile и добавить позже.

## Рекомендация
Используйте **Вариант 2** (системная установка), так как он:
- Не зависит от конфигурации Jenkins
- Работает на всех нодах, где установлен allure
- Проще в отладке
- Не требует прав администратора Jenkins