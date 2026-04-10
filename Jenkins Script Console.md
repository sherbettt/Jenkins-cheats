# Как принудительно (force) остановить сборку в дженкинс ?

### 🛑 Остановка сборки через Script Console

Script Console — это мощный инструмент для администраторов, позволяющий выполнять произвольные скрипты Groovy внутри Jenkins-мастера .

**Инструкция:**

1.  **Перейдите в Script Console:** Нажмите **Manage Jenkins** (Управление Jenkins) > **Script Console** . Обычно консоль доступна по адресу `https://<your-jenkins-url>/script`.
2.  **Выполните скрипт:** Вставьте один из следующих скриптов в консоль, обязательно заменив `"Имя_Вашей_Задачи"` и `Номер_Сборки` на свои значения.
 **Открываем script console:**
```
https://jenkins.runtel.ru/script
```

#### Скрипт 1: Комбинация `doStop()` и `doKill()` (Наиболее надежный)

Этот скрипт сначала пытается остановить сборку стандартным способом (`doStop`), а затем, если это не помогло, использует более жесткий метод `doKill` .

```groovy
def build = Jenkins.instance.getItemByFullName("Имя_Вашей_Задачи").getBuildByNumber(Номер_Сборки)
build.doStop()
build.doKill()
```

#### Скрипт 2: Завершение с результатом ABORTED

Этот метод останавливает сборку и помечает её результат как "ABORTED" (Прервано) .

```groovy
Jenkins.instance.getItemByFullName("Имя_Вашей_Задачи")
.getBuildByNumber(Номер_Сборки)
.finish(hudson.model.Result.ABORTED, new java.io.IOException("Принудительная остановка сборки"))
```

#### Скрипт 3: "Тяжелая артиллерия" — остановка треда

Если предыдущие методы не сработали и сборка буквально "висит" на мертвом процессе, можно попробовать найти и остановить её тред (поток выполнения). Используйте этот метод с **крайней осторожностью** .

```groovy
Thread.getAllStackTraces().keySet().each() {
    // Укажите уникальную часть имени задачи, чтобы случайно не остановить чужой процесс
    if (it.name.contains('Уникальная_Часть_Имени_Задачи')) {
        println "Останавливаю: $it.name"
        it.stop()
    }
}
```

### 🆚 Альтернативные методы

Если Script Console по какой-то причине недоступен, можно попробовать другие способы:

*   **Через интерфейс Jenkins (Web UI)** :
    1.  Зайдите на страницу сборки, которую нужно остановить.
    2.  В левом меню должна быть кнопка **"Cancel"** (Отменить) или красный крестик `X` рядом с прогрессом сборки в очереди. Это самый простой и предпочтительный способ, но он не всегда срабатывает на "зависших" сборках.
*   **Через Jenkins API** :
    Отправьте HTTP POST-запрос на специальный URL. Это удобно для автоматизации.
    ```bash
    curl -X POST http://<jenkins-url>/job/Имя_Вашей_Задачи/Номер_Сборки/stop
    ```
*   **Прямое удаление с диска (Linux)** :
    Если Jenkins никак не реагирует, можно удалить директорию сборки вручную.
    1.  Подключитесь к серверу, где работает Jenkins.
    2.  Перейдите в директорию с задачами:
        ```bash
        cd /var/lib/jenkins/jobs/Имя_Вашей_Задачи/builds/  # Путь может отличаться
        ```
    3.  Удалите папку, соответствующую номеру сборки:
        ```bash
        rm -rf Номер_Сборки
        ```
    4.  После этого в интерфейсе Jenkins нажмите **Manage Jenkins** > **Reload Configuration from Disk** (Перезагрузить конфигурацию с диска), чтобы обновить состояние.

----------------------------------------
<br/>



# Как стартовать сборку ?

### 🚀 Основные способы запуска сборки

#### 1. Запуск существующей задачи (Job)
Это самый простой и распространенный сценарий. Вы просто указываете имя задачи и инициируете её сборку.
```groovy
// Замените "Имя_Вашей_Задачи" на реальное имя
Jenkins.instance.getItemByFullName("Имя_Вашей_Задачи").scheduleBuild2(0)
```
*   **Пояснение:** Метод `scheduleBuild2(0)` ставит задачу в очередь с приоритетом 0 (обычный приоритет) .

#### 2. Запуск задачи с параметрами
Если ваша задача параметризирована, вы можете передать значения параметров непосредственно из скрипта.
```groovy
import hudson.model.*

// Замените "Имя_Задачи_С_Параметрами" на реальное имя
def job = Jenkins.instance.getItemByFullName("Имя_Задачи_С_Параметрами")

// Создаем список действий (параметров)
def params = [
    new StringParameterValue("BRANCH", "develop"),
    new StringParameterValue("ENVIRONMENT", "staging")
]
def action = new ParametersAction(params)

// Запускаем задачу с параметрами
job.scheduleBuild2(0, action)
```
*   **Пояснение:** Этот скрипт создает параметры `BRANCH` со значением `develop` и `ENVIRONMENT` со значением `staging`, после чего запускает задачу с ними .

#### 3. Запуск Pipeline (Multibranch Pipeline)
Запуск задачи, которая сама определяет свой Pipeline (например, из Jenkinsfile), выполняется немного иначе.
```groovy
// Замените "Имя_Pipeline" на реальное имя
def pipeline = Jenkins.instance.getItemByFullName("Имя_Pipeline")
def cause = new hudson.model.Cause.UserIdCause()
pipeline.scheduleBuild2(0, cause)
```
*   **Пояснение:** Здесь мы дополнительно передаем `UserIdCause`, чтобы в журнале сборки было видно, кто её инициировал (пользователь, выполнивший скрипт).

#### 4. Запуск на конкретном агенте (Node)
Если нужно гарантированно запустить задачу на определенном агенте, это тоже можно настроить.
```groovy
import hudson.model.labels.*

def job = Jenkins.instance.getItemByFullName("Имя_Задачи")
def label = LabelAtom.get("имя_вашего_узла")
def cause = new hudson.model.Cause.UserIdCause()

// Устанавливаем метку (лейбл) для запуска
job.setAssignedLabel(label)
job.scheduleBuild2(0, cause)

// Важно: после запуска лучше сбросить принудительную привязку к узлу,
// чтобы не влиять на последующие сборки.
// job.setAssignedLabel(null)
```
*   **Пояснение:** Сначала мы принудительно назначаем задаче узел для выполнения (`setAssignedLabel`), а затем запускаем её. Рекомендуется после запуска сбросить эту привязку, чтобы не нарушить обычное поведение задачи.

### 💡 Альтернативный способ: массовый запуск или интеграция

Помимо прямого запуска через интерфейс, вы можете использовать Script Console для более сложных сценариев, например, для запуска целой группы задач :
```groovy
// Запустить все задачи, начинающиеся с "backend-"
Jenkins.instance.getAllItems(Job).each { job ->
    if (job.name.startsWith("backend-")) {
        println "Запускаю: ${job.name}"
        job.scheduleBuild2(0)
    }
}
```
Также Script Console можно использовать **удаленно** через REST API или Jenkins CLI. Это удобно для автоматизации из скриптов или других инструментов .
*   **Пример через curl:**
    ```bash
    curl --user 'ваш_логин:ваш_токен' \
         --data-urlencode "script=Jenkins.instance.getItemByFullName('MyJob').scheduleBuild2(0)" \
         https://your-jenkins/scriptText
    ```
*   **Пример с файлом:**
    ```bash
    curl --user 'логин:токен' \
         --data-urlencode "script=$(< ./myscript.groovy)" \
         https://your-jenkins/scriptText
    ```

----------------------------------------
<br/>



# Как узнать о выполняющихся сборках
```groovy
def job = Jenkins.instance.getItemByFullName("BUILD_BACK_tag_dev")
def buildingBuilds = job.builds.findAll { it.isBuilding() }

if (buildingBuilds.isEmpty()) {
    println "Нет выполняющихся сборок для задачи ${job.name}"
} else {
    println "Найдены выполняющиеся сборки:"
    buildingBuilds.each { build ->
        println "  #${build.number} - с ${build.timestampString} - результат: ${build.result}"
    }
}
```

----------------------------------------
<br/>


# Как узнать












