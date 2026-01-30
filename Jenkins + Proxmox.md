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



