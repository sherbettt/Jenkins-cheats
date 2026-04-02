# Инструкция по настройке Allure в Jenkins UI

## Шаг 1: Подготовка архива Allure

Перед настройкой в Jenkins, распакуйте архив Allure:

```bash
# На сервере Jenkins (или на ноде, где работает сборка)
cd /root/programs/allure/allure-commandline/

# Распакуйте архив версии 2.38.1 (более новая)
unzip -q allure-commandline-2.38.1.zip -d allure-2.38.1

# Проверьте структуру
ls -la allure-2.38.1/
# Должны увидеть директории bin/, lib/, config/ и т.д.
```

## Шаг 2: Настройка в Jenkins UI

1. **Перейдите по ссылке**: https://jenkins.runtel.ru/manage/configureTools/

2. **Найдите раздел "Allure Commandline"**:
   - Прокрутите страницу вниз до раздела с инструментами
   - Или найдите по поиску "Allure"

3. **Добавьте новую установку**:
   - Нажмите "Add Allure Commandline"
   - Заполните поля:
     - **Name**: `allure-2.38.1` (или любое понятное имя)
     - **Install automatically**: **СНИМИТЕ ГАЛОЧКУ** (важно!)
     - **ALLURE_HOME**: укажите полный путь к распакованной директории:
       ```
       /root/programs/allure/allure-commandline/allure-2.38.1
       ```

4. **Сохраните изменения**:
   - Нажмите кнопку "Save" или "Apply" внизу страницы

## Шаг 3: Проверка конфигурации

1. **Перейдите в настройки конкретной задачи** (job):
   - Откройте задачу `cycle_single_node`
   - Нажмите "Configure"

2. **Проверьте post-блок**:
   Убедитесь, что в Jenkinsfile используется правильное имя установки:
   ```groovy
   allure([
       includeProperties: false,
       jdk: '',
       report: 'allure-report/',
       results: [[path: 'allure-results/']],
       commandline: 'allure-2.38.1'  // Должно совпадать с Name из шага 2
   ])
   ```

3. **Если в Jenkinsfile не указан commandline**, Jenkins будет использовать установку по умолчанию.

## Шаг 4: Альтернативный вариант - указать путь к архиву

Если не хотите распаковывать архив, можно указать путь к ZIP-файлу:

1. **В разделе "Allure Commandline"**:
   - **Install from Maven Central**: выберите "Install from file"
   - **File**: укажите путь к ZIP-архиву:
     ```
     /root/programs/allure/allure-commandline/allure-commandline-2.38.1.zip
     ```
   - **Subdirectory of unpacked archive**: оставьте пустым (или укажите `allure-2.38.1` если архив содержит поддиректорию)

2. **Сохраните изменения**

## Шаг 5: Тестирование

1. **Запустите сборку вручную**:
   - Вернитесь к задаче `cycle_single_node`
   - Нажмите "Build Now"

2. **Проверьте логи**:
   - В логах сборки ищите сообщения об Allure
   - Не должно быть ошибок "Failed to install"
   - Должно быть сообщение "Generating Allure report..."

3. **Проверьте результат**:
   - После успешной сборки на странице задачи должна появиться ссылка "Allure Report"
   - Или проверьте артефакты: должен быть `allure-report.zip`

## Если проблема не решена

### Вариант A: Проверьте права доступа
```bash
# Убедитесь, что пользователь Jenkins имеет доступ к директории
ls -la /root/programs/allure/allure-commandline/
chmod -R 755 /root/programs/allure/allure-commandline/allure-2.38.1
```

### Вариант B: Переместите Allure в директорию Jenkins
```bash
# Скопируйте Allure в домашнюю директорию Jenkins
cp -r /root/programs/allure/allure-commandline/allure-2.38.1 /var/lib/jenkins/tools/allure-2.38.1
chown -R jenkins:jenkins /var/lib/jenkins/tools/allure-2.38.1

# В Jenkins UI укажите путь: /var/lib/jenkins/tools/allure-2.38.1
```

### Вариант C: Временное решение - отключить Allure
Если нужно срочно запустить сборки, закомментируйте блок allure в Jenkinsfile:
```groovy
// allure([
//     includeProperties: false,
//     jdk: '',
//     report: 'allure-report/',
//     results: [[path: 'allure-results/']]
// ])
```

## Дополнительные настройки

### Для нескольких нод (agents)
Если сборка выполняется на нескольких нодах, нужно установить Allure на каждую ноду:

1. **Скопируйте архив** на каждую ноду
2. **Распакуйте** в одинаковый путь
3. **Настройте Global Tool Configuration** с указанием этого пути

### Прокси-настройки
Если Jenkins за прокси, может потребоваться настроить прокси для загрузки зависимостей:
- `Manage Jenkins` → `Plugin Manager` → `Advanced`
- Укажите Proxy Server

## Контакты для помощи
- **Администратор Jenkins**: для изменения глобальных настроек
- **Системный администратор**: для установки Allure на сервера
- **Разработчик**: для изменения Jenkinsfile