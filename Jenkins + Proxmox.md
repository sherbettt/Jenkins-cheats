# Jenkins + Proxmox

## **1. Установка плагина**

**Ссылка на плагин:**
- **Официальная:** https://plugins.jenkins.io/proxmox/
- **GitHub:** https://github.com/jenkinsci/proxmox-plugin

**Установка:**
```
https://jenkins.runtel.ru/manage/pluginManager/available
```

---

## **2. Создание облака Proxmox**

**Перейти:**
```
https://jenkins.runtel.ru/manage/cloud/
```
**ИЛИ:**
```
https://jenkins.runtel.ru/manage/configureClouds/
```
Нажать на кнопку **`+ New cloud`** ☁️

И вот уже есть https://jenkins.runtel.ru/manage/cloud/Datacenter(proxmox)/

---

## 🖥️ **3. Проверка в script console**

Несмотря на то, что версия плагина `Proxmox plugin 0.7.1` самая свежа, в нашем случае не получается через GUI провести полный настройки, придётся воспользоваться script console.

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
И увидим строку  ***`searchIndex=hudson.search.FixedSet@280f406a, nodes=[pmx6, prox4, pmx5]`*** - В плагине ВМ хранятся в nodes, а не в templates; в nodes уже есть [pmx6, prox4, pmx5]. Это и есть ВМ!


**Смотрим что в nodes**
```groovy
import org.jenkinsci.plugins.proxmox.*
import jenkins.model.Jenkins

def dc = Jenkins.instance.clouds[0]

println "=== Изучаем nodes ==="
println "Количество nodes: ${dc.nodes.size()}"

dc.nodes.eachWithIndex { node, i ->
    println "\nNode ${i+1}:"
    println "  Класс: ${node.getClass().name}"
    
    // Смотрим свойства ноды
    node.properties.each { key, value ->
        if (!key.contains("class") && !key.contains("metaClass")) {
            println "  ${key}: ${value}"
        }
    }
}
```
```c  
=== Изучаем nodes ===
Количество nodes: 3

Node 1:
  Класс: java.lang.String
  blank: false
  empty: false
  bytes: [112, 109, 120, 54]
  latin1: true

Node 2:
  Класс: java.lang.String
  blank: false
  empty: false
  bytes: [112, 109, 120, 53]
  latin1: true

Node 3:
  Класс: java.lang.String
  blank: false
  empty: false
  bytes: [112, 114, 111, 120, 52]
  latin1: true
Result: [pmx6, pmx5, prox4]
```

---

## **4. Credentials**

см.: 
- [JIRA.runtel.ru Credentials](https://jenkins.runtel.ru/manage/credentials/store/system/domain/jira.runtel.ru/)
- [Global Credentials](https://jenkins.runtel.ru/manage/credentials/store/system/domain/_/)

---




































