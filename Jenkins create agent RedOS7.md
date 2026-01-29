## Создание агента на развёрнутой вирутальной машине с RedOS v.7.3.6

### 1. Создайте директорию для Jenkins на целевой ноде:

```bash
ssh root@192.168.87.211

# Создайте директорию
mkdir -p /var/lib/jenkins

# Установите правильные права
chown root:root /var/lib/jenkins
chmod 755 /var/lib/jenkins

# Проверьте
ls -la /var/lib/ | grep jenkins
```

### 2. Альтернативно: измените рабочую директорию в настройках ноды

В Jenkins при настройке ноды вы можете указать другую рабочую директорию, например:
- `/tmp/jenkins`
- `/home/jenkins`
- `/opt/jenkins`

### 3. Перезапустите подключение ноды

После создания директории перезапустите ноду в Jenkins:
1. **Manage Jenkins** → **Manage Nodes and Clouds**
2. Найдите вашу ноду
3. Нажмите **Launch agent**

### 4. Если проблема сохраняется

Проверьте вручную, может ли Java запускаться:

```bash
ssh root@192.168.87.211 "cd /var/lib/jenkins && java -version"
```

### 5. Дополнительная проверка

Убедитесь, что система может найти Java:

```bash
ssh root@192.168.87.211 "which java && java -version && echo $PATH"
```

### 6. Установите Java 17 на RedOS:

```bash
ssh root@192.168.87.211

# Поиск доступных пакетов Java 17
yum search openjdk17

# Установите Java 17
yum install -y java-17-openjdk-devel

# Проверьте установку
java -version
```

### 7. Переключите систему на использование Java 17:

```bash
# Проверьте доступные версии Java
alternatives --config java

# Выберите Java 17 (должна появиться после установки)
```

### 8. Если пакет Java 17 не найден:

```bash
# Добавьте репозиторий с более новыми версиями (если нужно)
# Для RedOS может потребоваться EPEL или другие репозитории

# Или установите вручную
```

### 9. Альтернативное решение: обновите Java на агенте до версии 17

Если в репозиториях RedOS нет Java 17, скачайте и установите вручную:

```bash
# Скачайте OpenJDK 17
wget https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz

# Распакуйте
tar -xzf openjdk-17.0.2_linux-x64_bin.tar.gz -C /opt/

# Создайте симлинк
ln -sf /opt/jdk-17.0.2 /opt/jdk17

# Добавьте в PATH
echo 'export PATH=/opt/jdk17/bin:$PATH' >> /etc/profile.d/java17.sh
source /etc/profile.d/java17.sh

# Проверьте
java -version
```

### 10. После установки Java 17 проверьте:

```bash
java -version
# Должно показать версию 17 или выше
```

### 11. Перезапустите подключение ноды в Jenkins

После установки Java 17 нода должна успешно подключиться.

## Если нужно оставить Java 11 на агенте:

Вам нужно будет **понизить версию Java на Jenkins master** до 11, но это не рекомендуется, так как современные версии Jenkins требуют Java 11+.

**Рекомендую установить Java 17 на агенте** - это наиболее правильное решение.



### 12. Подключитесь к целевой ноде и установите Java:

```bash
ssh root@192.168.87.211

# Для RedOS (основана на RedHat)
dnf install -y java-11-openjdk-devel

# Или установите конкретную версию
dnf install -y java-1.8.0-openjdk-devel

# Проверьте установку
java -version
which java
```

### 13. Альтернативно: установите через alternatives

```bash
# Если есть несколько версий Java, выберите нужную
alternatives --config java
```

### 14. Если нужна конкретная версия Java:

```bash
# Поиск доступных пакетов Java
dnf search openjdk

# Установите нужную версию
dnf install -y java-11-openjdk-devel
```

### 15. Проверьте переменные окружения:

```bash
# Убедитесь, что Java в PATH
echo $PATH
which java

# Если не найдено, добавьте в PATH
export PATH=$PATH:/usr/lib/jvm/java-11-openjdk/bin
```

### 16. После установки Java перезапустите подключение ноды:

В Jenkins:
1. Перейдите в **Manage Jenkins** → **Manage Nodes and Clouds**
2. Найдите вашу ноду
3. Нажмите **Launch agent** или дождитесь автоматического переподключения

### 17. Альтернативное решение: указать путь к Java в конфигурации ноды

В настройках ноды в Jenkins вы можете указать путь к Java:

```bash
# Узнайте полный путь к java
which java
# Обычно: /usr/bin/java или /usr/lib/jvm/java-11-openjdk/bin/java

# Затем в конфигурации ноды укажите путь в поле "JavaPath"
```

### 18. Проверка работы:

После установки Java проверьте вручную:

```bash
ssh root@192.168.87.211 "java -version"
```

**ПОЛУЧАЕМ**
https://jenkins.runtel.ru/manage/credentials/store/system/domain/_/credential/736/
https://jenkins.runtel.ru/computer/redos-7/

### 19. Установим GIT:
```bash
dnf install -y git
dnf install -y make gcc gcc-c++ rpm-build rpmdevtools
```

### 20. Установим python3:
```bash
dnf list available python3*
dnf install -y python3 python3-devel

# Установите инструменты для сборки native модулей
yum install -y make gcc gcc-c++ openssl-devel bzip2-devel libffi-devel

# Для node-gyp (если используется)
yum install -y nodejs npm

# Проверьте установку
python3 --version
which python3
```

Если нужно свежее то:
```bash
# Установите Software Collections (SCL)
yum install -y centos-release-scl

# Установите Python 3.8 или 3.9
yum install -y rh-python38 rh-python39

# Активируйте Python 3.8
scl enable rh-python38 bash

# Или сделайте постоянным
echo 'source scl_source enable rh-python38' >> /etc/profile.d/python38.sh
```

Создайте симлинк python3 → python (если нужно):
```bash
# Проверьте, есть ли симлинк
ls -la /usr/bin/python3

# Если нужно создать симлинк python → python3
ln -sf /usr/bin/python3 /usr/bin/python
```

Установите pip (менеджер пакетов Python):
```bash
yum install -y python3-pip

# Обновите pip
python3 -m pip install --upgrade pip

# Проверьте
pip3 --version
```

### 21. Установим Ansible:
Установите Ansible на RedOS 7:
```bash
# Установите EPEL репозиторий (если еще не установлен)
dnf install -y epel-release

dnf install -y sshpass  # для SSH подключений

dnf install -y ansible

# Проверьте установку
ansible --version
which ansible-playbook
```

Проверьте пути:
```bash
# Убедитесь, что ansible-playbook доступен по указанному пути
ls -la /usr/bin/ansible-playbook

# Если установлен в другом месте, найдите его
find /usr -name ansible-playbook -type f 2>/dev/null
```

Если Ansible не находится в стандартных репозиториях:
```bash
# Альтернативная установка через pip
yum install -y python3-pip
pip3 install ansible

# Проверьте установку
/usr/local/bin/ansible-playbook --version
```

После установки проверьте пути:
```bash
# Найдите точный путь
which ansible-playbook
# Обычно: /usr/bin/ansible-playbook или /usr/local/bin/ansible-playbook

# Проверьте, что ansible-playbook доступен
ansible-playbook --version

# Должно показать что-то вроде:
# ansible-playbook [core 2.12.1]
```

Проверьте работу Ansible:
```bash
# Простой тест
ansible localhost -m ping

# Проверьте плейбук (если есть права)
ansible-playbook --syntax-check /var/lib/jenkins/ansible/playbooks/upload_to_redos7_repo.yml
```

<br/>
<br/>


## GPG ключи:
- Копируем /root/.gnupg/ с машины redos-8 (192.168.87.201);
- в директории `/root/.gnupg/` есть файлы, но они принадлежат пользователю с UID 1000, а не root. Это может вызывать проблемы с правами доступа.

## Решение: Настройка GPG для подписи RPM

### 1. Исправьте права доступа к GPG директории:

```bash
ssh root@192.168.87.211

# Измените владельца файлов GPG на root
chown -R root:root /root/.gnupg/

# Установите правильные права
chmod -R 700 /root/.gnupg/

# Проверьте права
ls -la /root/.gnupg/
```

### 2. Создайте или импортируйте GPG ключ для подписи:

#### Вариант A: Создайте новый GPG ключ
```bash
# Создайте новый ключ (введите нужные данные)
gpg --gen-key

# Или без интерактивного режима
cat > gpg_batch << EOF
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 2048
Subkey-Type: RSA
Subkey-Length: 2048
Name-Real: Jenkins RPM Signing
Name-Email: jenkins@runtel.ru
Expire-Date: 0
%commit
%echo done
EOF

gpg --batch --generate-key gpg_batch
rm gpg_batch
```

#### Вариант B: Импортируйте существующий ключ
```bash
# Если у вас есть существующий ключ
gpg --import your_private_key.asc
```

### 3. Проверьте наличие ключей:

```bash
# Список ключей
gpg --list-keys
gpg --list-secret-keys

# Экспортируйте публичный ключ
gpg --export -a "Jenkins RPM Signing" > RPM-GPG-KEY-runtel
```

### 4. Настройте RPM для использования GPG ключа:

```bash
# Создайте конфигурацию RPM
cat > /etc/rpm/macros.dist << EOF
%_signature gpg
%_gpg_path /root/.gnupg
%_gpg_name Jenkins RPM Signing
%_gpgbin /usr/bin/gpg
EOF

# Или добавьте в ~/.rpmmacros
echo '%_gpg_name Jenkins RPM Signing' >> ~/.rpmmacros
```

### 5. Проверьте подпись RPM:

```bash
# Создайте тестовый RPM или попробуйте подписать существующий
echo "Test" > test.txt
tar -czf test-1.0.0.tar.gz test.txt

# Попробуйте подписать
rpm --addsign /path/to/your.rpm
```

### 6. Если проблема сохраняется:

Проверьте наличие всех необходимых пакетов:

```bash
# Убедитесь, что все установлено
yum install -y rpm-sign gnupg2 expect

# Проверьте пути
which rpm
which rpmsign
which gpg

# Проверьте версии
rpm --version
gpg --version
```

### 7. Альтернативное решение - используйте прямой вызов gpg:

Если `rpm --addsign` не работает, можно подписывать через gpg напрямую:

```bash
# Подпись через gpg
gpg --detach-sign --armor /path/to/package.rpm
```

```bash
┌─ root
├─ redos7
└─ ~/.gnupg # gpg --list-keys
/root/.gnupg/pubring.kbx
------------------------
pub   rsa4096 2019-04-03 [SC]
      ABDA81F04BB74A21936B194F325CE60C3AD367DE
uid         [ неизвестно ] runtel (RUNTEL GNUPG) <support@runtel.ru>
sub   rsa4096 2019-04-03 [E]

┌─ root
├─ redos7
└─ ~/.gnupg # gpg --list-secret-keys
/root/.gnupg/pubring.kbx
------------------------
sec   rsa4096 2019-04-03 [SC]
      ABDA81F04BB74A21936B194F325CE60C3AD367DE
uid         [ неизвестно ] runtel (RUNTEL GNUPG) <support@runtel.ru>
ssb   rsa4096 2019-04-03 [E]
```

GPG ключ есть, но он помечен как `[ неизвестно ]` - это означает, что ключу не доверяют. Нужно установить доверие и настроить RPM для использования этого ключа.

## Решение: Настройка доверия и конфигурация RPM

### 1. Установите доверие к GPG ключу:

```bash
ssh root@192.168.87.211

# Установите максимальное доверие к ключу
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key ABDA81F04BB74A21936B194F325CE60C3AD367DE trust

# Или альтернативный способ
gpg --edit-key ABDA81F04BB74A21936B194F325CE60C3AD367DE
# В интерактивном режиме введите:
# trust
# 5
# y
# quit
```

### 2. Проверьте доверие:

```bash
gpg --list-keys
# Теперь должно показывать [полное] вместо [неизвестно]
```

### 3. Настройте RPM для использования этого ключа:

```bash
# Создайте или отредактируйте конфигурационный файл
cat > ~/.rpmmacros << EOF
%_signature gpg
%_gpg_path /root/.gnupg
%_gpg_name runtel (RUNTEL GNUPG) <support@runtel.ru>
%_gpgbin /usr/bin/gpg
EOF

# или
#%_topdir /var/lib/jenkins/workspace/pbx_v2_redos
#%_builddir /var/lib/jenkins/workspace/pbx_v2_redos
#%_sourcedir /var/lib/jenkins/workspace/pbx_v2_redos
#%_buildroot /var/lib/jenkins/workspace/pbx_v2_redos
%_signature gpg
%_gpg_path /root/.gnupg
%_gpg_name runtel
%_gpgbin /usr/bin/gpg2
%_unitdir /usr/lib/systemd/system/

# Или используйте ID ключа
echo '%_gpg_name ABDA81F04BB74A21936B194F325CE60C3AD367DE' >> ~/.rpmmacros
```

### 4. Проверьте конфигурацию RPM:

```bash
# Проверьте настройки
rpm --showrc | grep gpg

# Или
rpm -E %_gpg_name
```

### 5. Протестируйте подпись RPM:

```bash
# Создайте простой тестовый файл
echo "Test" > test.txt
tar -czf test-1.0.0.tar.gz test.txt

# Попробуйте подписать любой RPM файл (если есть)
if [ -f /var/lib/jenkins/workspace/rt_v2_redos7/rpmbuild_100/RPMS/x86_64/*.rpm ]; then
    rpm --addsign /var/lib/jenkins/workspace/rt_v2_redos7/rpmbuild_100/RPMS/x86_64/*.rpm
    echo "Подпись успешна!"
else
    echo "RPM файлы не найдены для теста"
fi
```

### 6. Если нужно, переустановите rpm-sign:

```bash
# Убедитесь, что rpm-sign установлен правильно
yum reinstall -y rpm-sign
```

### 7. Проверьте наличие rpmsign:

```bash
# Проверьте, что rpmsign доступен
which rpmsign
ls -la /usr/bin/rpmsign

# Если нет, найдите пакет
yum provides */rpmsign
```

### 8. Альтернатива: используйте прямой вызов gpg:

Если `rpm --addsign` все еще не работает:

```bash
# Найдите путь к rpmsign
find /usr -name rpmsign -type f 2>/dev/null

# Или используйте полный путь
/usr/bin/rpm --addsign package.rpm
```

### 9. После настройки перезапустите сборку в Jenkins.

## Если проблема сохраняется:

Проверьте логи подробнее:

```bash
# Включите debug режим для RPM
RPMDEBUG=1 rpm --addsign package.rpm 2>&1

# Или проверьте с strace
strace -f rpm --addsign package.rpm
```
<br/>
<br/>



## Скопировать содеержимое /var/lib/jenkins/ansible/ с машины 192.168.87.24.

<br/>
<br/>


## Установка готового RPM пакета.

```
┌─ root
├─ redos7
└─ /var/lib/jenkins/workspace # ll
итого 62068
drwxr-xr-x.  4 root root     4096 авг 28 11:37  ./
drwxr-xr-x.  7 root root     4096 авг 28 11:33  ../
drwxr-xr-x. 11 root root     4096 авг 28 11:37  rt_v2_redos7/
drwxr-xr-x.  2 root root     4096 авг 28 11:37 'rt_v2_redos7@tmp'/
-rw-r--r--.  1 root root 31767149 авг 28 10:46  runtel-web-v2-2.21.52-103.x86_64.rpm
-rw-r--r--.  1 root root 31767105 авг 28 11:37  runtel-web-v2-2.21.52-104.x86_64.rpm
-rw-r--r--.  1 root root      934 авг 27 18:58  workspaces.txt
```

### 1. Установите RPM пакет:

```bash
# Базовая установка
yum install -y ./runtel-web-v2-2.21.52-104.x86_64.rpm

# Или с помощью rpm
rpm -ivh runtel-web-v2-2.21.52-104.x86_64.rpm

# Или если нужно обновить существующую версию
rpm -Uvh runtel-web-v2-2.21.52-104.x86_64.rpm
```

### 2. Проверьте установку:

```bash
# Проверьте, что пакет установлен
rpm -qa | grep runtel-web-v2

# Посмотрите информацию о пакете
rpm -qi runtel-web-v2

# Посмотрите какие файлы установил пакет
rpm -ql runtel-web-v2
```

### 3. Если нужно проверить зависимости перед установкой:

```bash
# Проверьте зависимости
rpm -qpR runtel-web-v2-2.21.52-104.x86_64.rpm

# Тестовая установка (без реальной установки)
rpm -ivh --test runtel-web-v2-2.21.52-104.x86_64.rpm
```

### 4. Дополнительные опции установки:

```bash
# Установка с игнорированием зависимостей (не рекомендуется)
rpm -ivh --nodeps runtel-web-v2-2.21.52-104.x86_64.rpm

# Установка с принудительной перезаписью
rpm -ivh --force runtel-web-v2-2.21.52-104.x86_64.rpm
```

### 5. Если пакет уже установлен и нужно обновить:

```bash
# Обновление пакета
rpm -Uvh runtel-web-v2-2.21.52-104.x86_64.rpm

# Или через yum (лучше для обработки зависимостей)
yum update -y ./runtel-web-v2-2.21.52-104.x86_64.rpm
```

## Рекомендуемый способ:

```bash
# Самый правильный способ - через yum для автоматического разрешения зависимостей
yum install -y ./runtel-web-v2-2.21.52-104.x86_64.rpm
```

## После установки проверьте:

```bash
# Проверьте статус службы (если пакет устанавливает службу)
systemctl status runtel-web-v2

# Или посмотрите что установилось
find / -name "*runtel*" -type f 2>/dev/null | head -10
```

## Если возникнут ошибки зависимостей:

```bash
# Установите недостающие зависимости
yum install -y <missing-dependency>

# Или посмотрите какие зависимости требуются
rpm -qpR runtel-web-v2-2.21.52-104.x86_64.rpm
```

<br/>
<br/>


## Файл .netrc в корне.
```bash
┌─ root
├─ redos7
└─ ~ # ccat .netrc 
machine gitlab.runtel.org
login jenkins
password <password>
```
