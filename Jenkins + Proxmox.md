# Jenkins + Proxmox

## 🔧 **1. Установка плагина**

**Ссылка на плагин:**
- **Официальная:** https://plugins.jenkins.io/proxmox/
- **GitHub:** https://github.com/jenkinsci/proxmox-plugin

**Установка:**
```
https://jenkins.runtel.ru/manage/pluginManager/available
```

---

## ☁️ **2. Создание облака Proxmox**

**Перейти:**
```
https://jenkins.runtel.ru/manage/cloud/
```
**ИЛИ:**
```
https://jenkins.runtel.ru/manage/configureClouds/
```
Нажать на кнопку **`+ New cloud`**

И вот уже есть https://jenkins.runtel.ru/manage/cloud/Datacenter(proxmox)/

---

## ⚙️ **3. Настройка подключения**

**Форма:**
```
Name: Proxmox-Cloud
Credentials: [Add] → Jenkins → Username with password
  Username: root@pam
  Password: [ваш пароль]
Proxmox server URL: https://ВАШ_IP:8006/api2/json
Ignore SSL: ☑ (если самоподписанный)
[Test Connection] → Должен быть "Success"
[Save]
```

---

## 🖥️ **4. Настройка виртуальной машины**

**В той же форме ниже:**
┌─────────────────────────────────────┐
│ Virtual Machines                    │
├─────────────────────────────────────┤
│ [Add]                              │ ← КЛИК!
│                                     │
│ VM Id: 9000 (ID шаблона)           │
│ Description: Jenkins Agent         │
│                                     │
│ Launch method:                     │
│ → Launch via execution on master   │
│                                     │
│ Labels: proxmox-linux              │
│ Usage: Use as much as possible     │
└─────────────────────────────────────┘

---

## ✅ **5. Проверка**

**Создать тестовый Pipeline:**
```
https://jenkins.runtel.ru/view/all/newJob
```
```groovy
pipeline {
    agent { label 'proxmox-linux' }
    stages {
        stage('Test') {
            steps { echo 'Hello Proxmox!' }
        }
    }
}
```

---

## 🖥️ **5. Проверка в script console**

**Открываем script console:**
```
https://jenkins.runtel.ru/script
```
```groovy
import jenkins.model.Jenkins

println "=== Проверка облаков ==="
Jenkins.instance.clouds.each { cloud ->
    println "Облако: ${cloud.name}"
    println "Класс: ${cloud.getClass().name}"
    println "Кол-во ВМ: ${cloud.vmConfigs?.size() ?: 0}"
    println "---"
}
```

**Через JSON конфигурацию**
```groovy
import jenkins.model.Jenkins
import net.sf.json.JSONObject

println "=== Альтернативный метод ==="

// Получаем текущую конфигурацию облака
def config = Jenkins.instance.getDescriptor("org.jenkinsci.plugins.proxmox.ProxmoxCloud")

// Создаем JSON с настройками ВМ
def vmJson = new JSONObject()
vmJson.put("vmId", "0")
vmJson.put("description", "Test Agent")
vmJson.put("labels", "test-proxmox")
vmJson.put("launchMethod", "Launch agent via execution of command on master")
vmJson.put("command", "echo 'Hello from VM'")
vmJson.put("proxmoxNode", "pve")
vmJson.put("storage", "local-lvm")
vmJson.put("cores", "2")
vmJson.put("memory", "2048")
vmJson.put("diskSize", "20")

println "JSON ВМ: ${vmJson.toString()}"
println "Добавьте эту конфигурацию вручную через UI"
```

**Изучаем структуру Datacenter**
```groovy
import org.jenkinsci.plugins.proxmox.*
import jenkins.model.Jenkins

println "=== Изучаем Datacenter ==="

def dc = Jenkins.instance.clouds.find { it.name == "Datacenter(proxmox)" }
if (!dc) {
    println "❌ Облако не найдено!"
    return
}

println "✅ Облако: ${dc.name}"
println "Класс: ${dc.getClass().name}"

// Смотрим все методы класса
println "\nДоступные методы:"
dc.metaClass.methods.name.unique().sort().each { println "- $it" }

// Проверяем поля
println "\nПоля объекта:"
dc.properties.each { key, value ->
    if (!key.contains("class") && !key.contains("metaClass")) {
        println "${key}: ${value?.getClass()?.name}"
    }
}
```
И увидим строку  ***`searchIndex=hudson.search.FixedSet@280f406a, nodes=[pmx6, prox4, pmx5]`*** - это и есть наши "железные" Proxmox сервера

---









































