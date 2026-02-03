# Jenkins + Proxmox

## **1. Установка плагинов**

**Ссылка на плагины:**
- **Официальная:** https://plugins.jenkins.io/proxmox/
- **GitHub:** https://github.com/jenkinsci/proxmox-plugin
- **SSH:** https://plugins.jenkins.io/ssh/
- **SSH Credentials:** https://plugins.jenkins.io/ssh-credentials/


**Установка:**
```
https://jenkins.runtel.ru/manage/pluginManager/available
```

---------------------------------------
<br/>

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

----------------------------------------
<br/>

## 🖥️ **3. Проверка в script console**

Несмотря на то, что версия плагина `Proxmox plugin 0.7.1` самая свежа, в нашем случае не получается через GUI провести полный настройки, придётся воспользоваться script console.

**Открываем script console:**
```
https://jenkins.runtel.ru/script
```


<details>
<summary>❗ script console ❗</summary>

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


**Смотрим SSH ключи, токены и т.д.**
```groovy
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.common.StandardUsernameCredentials

def creds = CredentialsProvider.lookupCredentials(
    StandardUsernameCredentials.class,
    Jenkins.instance,
    null,
    null
)

creds.each { cred ->
    println "ID: ${cred.id}"
    println "Username: ${cred.username}"
    println "Description: ${cred.description}"
    println "---"
}
```
</details>

----------------------------------------
<br/>

## **4. Credentials**

см.: 
- [JIRA.runtel.ru Credentials](https://jenkins.runtel.ru/manage/credentials/store/system/domain/jira.runtel.ru/)
- [Global Credentials](https://jenkins.runtel.ru/manage/credentials/store/system/domain/_/)

```text
Jenkins → Credentials → System → Global credentials → Add Credentials
↓
Тип: SSH Username with private key
Username: root
Private Key: 
  • Enter directly (вставить содержимое /var/lib/jenkins/.ssh/id_rsa или ~/.ssh с deb12-builder)
ID: proxmox-cycle-builder
Description: SSH доступ к контейнеру cycle-single-builder
```

```text
deb12-builder (Jenkins агент)
    ↓ имеет SSH ключ (~/.ssh/id_rsa)
    ↓ ключ добавлен в Jenkins Credentials
    ↓ Jenkins использует ключ для подключения
cycle-single-builder (контейнер 192.168.87.55)
    ↓ в ~/.ssh/authorized_keys добавлен публичный ключ
    ↓ принимает подключения по SSH
```

***Пример:***
<p align="center">
  <img src="https://github.com/sherbettt/Jenkins-cheats/blob/main/images/Jenkins_System_3.png" alt="Jenkins Credentials new">
</p>


**Смотрим SSH ключи, токены и т.д. https://jenkins.runtel.ru/script**
```groovy
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.common.StandardUsernameCredentials

def creds = CredentialsProvider.lookupCredentials(
    StandardUsernameCredentials.class,
    Jenkins.instance,
    null,
    null
)

creds.each { cred ->
    println "ID: ${cred.id}"
    println "Username: ${cred.username}"
    println "Description: ${cred.description}"
    println "---"
}
```

----------------------------------------
<br/>

## **5. Создать pipeline для проверки соединения**

ТЕстовый pipeline для проверки соединения.
```groovy
// Простейший тест без credentials
pipeline {
    agent {
        label 'deb12-builder'
    }
    
    stages {
        stage('Простой тест') {
            steps {
                sh '''
                    # Просто используем ключ который уже есть на ноде
                    ssh -o StrictHostKeyChecking=no \
                        root@192.168.87.55 "
                        echo 'Контейнер: ' \$(hostname)
                        echo 'Работает!'
                    "
                '''
            }
        }
    }
}
```


<details>
<summary>❗ тестовый пайплайн ❗</summary>

```groovy
pipeline {
    agent {
        label 'deb12-builder'
    }
    
    stages {
        stage('Тест SSH к контейнеру') {
            steps {
                script {
                    echo "🔄 Тестируем подключение к контейнеру Proxmox"
                    echo "🎯 IP: 192.168.87.55"
                    echo "🏷️ Контейнер: cycle-single-builder"
                    
                    // Тест 1: Простое подключение
                    sh '''
                        echo "=== Тест 1: Простое подключение ==="
                        ssh -o StrictHostKeyChecking=no \
                            root@192.168.87.55 "hostname"
                    '''
                    
                    // Тест 2: Полная информация
                    sh '''
                        echo "=== Тест 2: Информация о контейнере ==="
                        ssh -o StrictHostKeyChecking=no \
                            root@192.168.87.55 '
                            echo "🎯 Хост: $(hostname)"
                            echo "📅 Дата: $(date)"
                            echo "💾 Диск:"
                            df -h /
                            echo "🧠 Память:"
                            free -h
                            echo "🌐 IP: $(hostname -I)"
                            echo "✅ Контейнер готов к работе!"
                        '
                    '''
                }
            }
        }
        
        stage('Тест деплоя') {
            steps {
                script {
                    sh '''
                        echo "=== Тест деплоя файлов ==="
                        
                        # Создаём тестовый файл
                        echo "# Тестовый деплой из Jenkins" > test-deploy.txt
                        echo "Build: ${BUILD_NUMBER}" >> test-deploy.txt
                        echo "Date: $(date)" >> test-deploy.txt
                        echo "From: deb12-builder" >> test-deploy.txt
                        
                        echo "📄 Содержимое тестового файла:"
                        cat test-deploy.txt
                        
                        # Копируем в контейнер
                        echo "📤 Копируем в контейнер..."
                        scp -o StrictHostKeyChecking=no \
                            test-deploy.txt \
                            root@192.168.87.55:/tmp/
                        
                        # Проверяем в контейнере
                        echo "🔍 Проверяем в контейнере..."
                        ssh -o StrictHostKeyChecking=no \
                            root@192.168.87.55 '
                            echo "📄 Файл в контейнере:"
                            cat /tmp/test-deploy.txt
                            echo ""
                            echo "📊 Директория /tmp/:"
                            ls -la /tmp/test-deploy.txt
                        '
                    '''
                }
            }
        }
        
        stage('Проверка окружения') {
            steps {
                script {
                    sh '''
                        echo "=== Проверка окружения в контейнере ==="
                        
                        ssh -o StrictHostKeyChecking=no \
                            root@192.168.87.55 '
                            echo "🐍 Python:"
                            python3 --version 2>/dev/null || echo "Python не установлен"
                            
                            echo ""
                            echo "🟢 Node.js:"
                            node --version 2>/dev/null || echo "Node.js не установлен"
                            
                            echo ""
                            echo "☕ Java:"
                            java -version 2>&1 | head -1 || echo "Java не установлена"
                            
                            echo ""
                            echo "📦 Установленные пакеты (первые 10):"
                            dpkg -l | tail -11
                        '
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo """
            🎉 ВСЁ РАБОТАЕТ!
            
            ✅ SSH подключение: работает
            ✅ Деплой файлов: работает
            ✅ Команды выполняются в контейнере
            
            Теперь можно создавать реальный Pipeline для вашего приложения!
            
            Контейнер: cycle-single-builder (192.168.87.55)
            Jenkins агент: deb12-builder
            Статус: ГОТОВ к использованию
            """
        }
        failure {
            echo "❌ Что-то пошло не так"
        }
    }
}
```
</details> 


----------------------------------------
<br/>


## **6. Настроить pipeline**

***Пример:***
<p align="center">
  <img src="https://github.com/sherbettt/Jenkins-cheats/blob/main/images/Jenkins_System_2.png" alt="Jenkins Pipeline Settinfs">
</p>



----------------------------------------
<br/>













