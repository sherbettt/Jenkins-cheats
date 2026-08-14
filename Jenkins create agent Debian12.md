# Создание агента на развёрнутой виртуальной машине с Debian 12

## 1. Исходные данные

### Целевая машина (агент)
- **IP адрес**: 192.168.87.118
- **Имя хоста**: ai2
- **ОС**: Debian GNU/Linux 12 (bookworm)
- **Ядро**: 6.1.0-42-amd64
- **Пользователь**: root

### Машина Jenkins мастера
- **IP адрес**: 192.168.87.11
- **Имя хоста**: jenkins-updated

---

## 2. Выполненные действия

### 2.1. Настройка SSH доступа

**Создание SSH ключа для агента:**
```bash
# На агентской машине (ai2)
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa_jenkins -N ""
```

**Созданные ключи закинуть на https://gitlab.runtel.org/** :  в раздел технического пользователя gitlab, от имени которого будет на ноду вытягиваться репозиторий с проектом.

Для этого на ноде желательно сразу создать файл ***`.netrc`***.
```bash
root@ai2 /opt/runtel/robot
13:46:51 # ll ~/.netrc 
-rw-r--r-- 1 root root 76 Aug 14 12:45 /root/.netrc

root@ai2 /opt/runtel/robot
14:00:46 # cat ~/.netrc 
machine gitlab.runtel.org
login jenkins
password <PASS_WORD>

```

**Настройка авторизации:**
```bash
# Добавление публичного ключа в authorized_keys
cat /root/.ssh/id_rsa_jenkins.pub >> /root/.ssh/authorized_keys

# Настройка прав доступа
chmod 600 /root/.ssh/authorized_keys
chmod 600 /root/.ssh/id_rsa_jenkins
chmod 644 /root/.ssh/id_rsa_jenkins.pub
chmod 700 /root/.ssh
```

**Содержимое ~/.ssh/authorized_keys:**
- Добавлены несколько публичных ключей для доступа разных пользователей
- Присутствуют ключи Jenkins (jenkins@jenkins, root@jenkins)
- Настроены правильные права доступа

### 2.2. Проверка SSH соединения

**С машины Jenkins мастера:**
```bash
kkorablin@Think ~ > ssh root@jenkins-updated
root@jenkins-updated ~ > ssh root@192.168.87.118
# Подключение успешно установлено
```

### 2.3. Установка необходимого ПО

**Базовые пакеты:**
```bash
apt install -y \
    git ansible make gcc g++ \
    gnupg gnupg2 \
    python3 python3-pip python3-venv python3-dev \
    openssh-server curl wget sshpass build-essential \
    unzip zip tar gzip bzip2 xz-utils
```

**Установка openjdk 17:**
```bash
apt search openjdk
apt install -y openjdk-17-jdk openjdk-17-doc openjdk-17-dbg
java --version
```

**Проверка версий:**
```
git version 2.39.5
Python 3.11.2
pip 23.0.1
OpenJDK 17.0.20
```

### 2.4. Создание структуры директорий

```bash
# Основные директории для Jenkins агента
mkdir -p /var/lib/jenkins/workspace
mkdir -p /var/lib/jenkins/ansible
mkdir -p /opt/jenkins/{agent,workspace,tools,logs}  # опционально

# Установка прав
chown -R root:root /var/lib/jenkins
chmod 755 /var/lib/jenkins
chmod 755 /var/lib/jenkins/workspace
chmod 755 /opt/jenkins
chmod 755 /opt/jenkins/workspace
```

---

## 3. Действия, которые необходимо выполнить

### 3.1. Настройка Jenkins агента в UI

1. **Вход в Jenkins UI**: **https://jenkins.runtel.ru/**
    > [!NOTE]
    > Вход по адресу http://192.168.87.11:8080 на данный момент не работает, т.к. применяется Teleport.

3. **Создание нового агента:**
   - Dashboard → Manage Jenkins → Nodes → New Node
   - **Имя**: `ai2-agent`
   - **Тип**: `Permanent Agent`

4. **Настройки агента:**
   ```
   # Основные параметры
   Description: Debian 12 Agent on ai2
   Number of executors: 2
   Remote root directory: /var/lib/jenkins/workspace
   Labels: debian bookworm amd64 ai2
   Usage: Use this node as much as possible
   
   # Способ запуска
   Launch method: Launch agents via SSH
   Host: 192.168.87.118
   Credentials: 
     - Kind: SSH Username with private key
     - Scope: Global
     - Username: root
     - Private Key: Enter directly (вставить приватный ключ)
   
   Host Key Verification Strategy: Non verifying Verification Strategy
   
   # Дополнительно
   Availability: Keep this agent online as much as possible
   ```

### 3.2. Получение приватного ключа для Jenkins

**На машине Jenkins мастера (jenkins-updated):**
```bash
# Просмотр существующих ключей
cat ~/.ssh/id_rsa
# или
cat /var/lib/jenkins/.ssh/id_rsa

# Если ключей нет - создать новый
ssh-keygen -t rsa -b 4096 -f /tmp/jenkins_ai2_key -N ""
cat /tmp/jenkins_ai2_key  # приватный ключ для вставки в Jenkins UI
```

### 3.3. Создание systemd сервиса для агента

```bash
# Создание скрипта запуска
cat > /opt/jenkins-agent.sh << 'EOF'
#!/bin/bash
JENKINS_URL="http://192.168.87.11:8080"
AGENT_NAME="ai2-agent"
WORK_DIR="/var/lib/jenkins/workspace"

if [ ! -f /var/lib/jenkins/agent.jar ]; then
    wget -O /var/lib/jenkins/agent.jar ${JENKINS_URL}/jnlpJars/agent.jar
fi

java -jar /var/lib/jenkins/agent.jar \
    -url ${JENKINS_URL} \
    -name ${AGENT_NAME} \
    -workDir ${WORK_DIR}
EOF

chmod +x /opt/jenkins-agent.sh
```

### 3.4. Настройка переменных окружения

```bash
cat > /etc/profile.d/jenkins.sh << 'EOF'
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export MAVEN_HOME=/usr/share/maven
export PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH
EOF

source /etc/profile.d/jenkins.sh
```

### 3.5. Проверка работоспособности

```bash
# Проверка установленных инструментов
java -version
mvn -version
git --version
python3 --version
ansible --version
docker --version

# Проверка SSH соединения с Jenkins мастера
ssh -v root@192.168.87.11 "echo 'Connection OK'"
```

### 3.6. Создание тестового задания

**В Jenkins UI создать Freestyle job:**
1. **New Item** → `test-ai2-agent`
2. **Restrict where this project can be run**: `ai2-agent`
3. **Build** → **Execute shell**:

```bash
#!/bin/bash
echo "=== Jenkins Agent Test ==="
echo "Hostname: $(hostname)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "User: $(whoami)"
echo "Java: $(java -version 2>&1 | head -n1)"
echo "Git: $(git --version)"
echo "Python: $(python3 --version)"
echo "Ansible: $(ansible --version 2>&1 | head -n1)"
echo "Working directory: $(pwd)"
echo "=== Test completed successfully ==="
```

### 3.7. Настройка мониторинга

```bash
# Проверка статуса агента в Jenkins
# Dashboard → Manage Jenkins → Nodes → ai2-agent

# Просмотр логов на агенте
journalctl -u jenkins-agent -f
tail -f /var/log/auth.log

# Проверка процессов
ps aux | grep agent.jar
```

---

## 4. Возможные проблемы и их решение

### 4.1. SSH подключение не работает
```bash
# Проверка прав
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_rsa

# Проверка SSH сервера
systemctl status sshd
systemctl restart sshd

# Проверка логов
tail -f /var/log/auth.log
```

### 4.2. Агент не подключается к Jenkins
```bash
# Проверка доступности Jenkins мастера
curl -I http://192.168.87.11:8080

# Проверка файрвола
ufw allow from 192.168.87.11 to any port 22
iptables -A INPUT -s 192.168.87.11 -p tcp --dport 22 -j ACCEPT
```

### 4.3. Недостаточно прав на директории
```bash
# Сброс прав
chown -R root:root /var/lib/jenkins
chmod 755 /var/lib/jenkins
chmod 755 /var/lib/jenkins/workspace
chmod 755 /opt/jenkins
```

---

## 5. Итоговая структура

```
/var/lib/jenkins/
├── workspace/          # Рабочая директория для сборок
├── ansible/           # Ansible файлы
├── agent.jar          # Jenkins агент
└── logs/              # Логи агента

/opt/jenkins/
├── agent/             # Файлы агента
├── workspace/         # Альтернативная рабочая директория
└── tools/             # Инструменты сборки

~/.ssh/
├── authorized_keys    # Публичные ключи для доступа
├── id_rsa            # Приватный ключ
└── id_rsa.pub        # Публичный ключ
```

---

## 6. Команды для быстрой проверки

```bash
# Проверка всех компонентов
echo "=== System Info ===" && \
hostname && \
cat /etc/os-release | grep PRETTY_NAME && \
echo "=== Tools ===" && \
java -version 2>&1 | head -n1 && \
git --version && \
python3 --version && \
ansible --version 2>&1 | head -n1 && \
docker --version && \
echo "=== Directories ===" && \
ls -la /var/lib/jenkins/ && \
echo "=== SSH Status ===" && \
systemctl status sshd | grep Active && \
echo "=== Network ===" && \
ip addr show | grep "inet "
```

