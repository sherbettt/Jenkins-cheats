## Создание агента на развёрнутой виртуальной машине с RedOS v.7.3.6 (Oracle 9.7)

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
chmod -R 600 /root/.gnupg/*

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



## Скопировать содержимое /var/lib/jenkins/ansible/ с машины 192.168.87.24.

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

<br/>
<br/>


## Настройка и проверка подписи RPM (дополнено)

### 1. Создание тестового RPM для проверки подписи

```bash
# Создайте директорию для тестов
mkdir -p ~/scripts
cd ~/scripts

# Создайте простой spec-файл для тестового пакета
cat > test.spec << 'EOF'
Summary: Test package
Name: test
Version: 1.0
Release: 1
License: GPL
Group: Development/Tools
BuildArch: noarch

%description
Test package for RPM signing

%files
EOF

# Соберите тестовый RPM
# --define "_rpmdir $(pwd)" указывает директорию для сохранения собранного RPM
rpmbuild -bb test.spec --define "_rpmdir $(pwd)"

# Проверьте, что RPM создан
ls -la noarch/test-1.0-1.noarch.rpm
```

### 2. Подпись тестового RPM

```bash
# Подпишите созданный RPM
# Команда запросит пароль, если ключ защищен
rpm --addsign /root/scripts/noarch/test-1.0-1.noarch.rpm

# Проверьте подпись (должна показывать NOKEY, так как публичный ключ еще не импортирован)
rpm -Kv /root/scripts/noarch/test-1.0-1.noarch.rpm
```

### 3. Импорт публичного ключа в систему RPM

```bash
# Экспортируйте публичный ключ из связки GPG
# ABDA81F04BB74A21936B194F325CE60C3AD367DE - ID вашего ключа
gpg --export -a ABDA81F04BB74A21936B194F325CE60C3AD367DE > /root/.gnupg/RPM-GPG-KEY-runtel

# Импортируйте ключ в систему RPM
rpm --import /root/.gnupg/RPM-GPG-KEY-runtel

# Проверьте импортированные ключи
rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n'
# Должен появиться ключ с ID 3ad367de
```

### 4. Проверка подписи после импорта ключа

```bash
# Теперь проверка должна показывать OK для всех проверок
rpm -Kv /root/scripts/noarch/test-1.0-1.noarch.rpm

# Пример успешного вывода:
# /root/scripts/noarch/test-1.0-1.noarch.rpm:
#     Заголовок V4 RSA/SHA256 Signature, key ID 3ad367de: OK
#     Заголовок SHA256 digest: OK
#     Заголовок SHA1 digest: OK
#     Payload SHA256 digest: OK
#     MD5 digest: OK
```

### 5. Просмотр информации о GPG ключах

```bash
# Просмотр всех секретных ключей с отпечатками и keygrip
gpg --list-secret-keys --with-keygrip

# Keygrip используется для идентификации ключа в gpg-agent
# Пример вывода:
# sec   rsa4096 2019-04-03 [SC]
#       ABDA81F04BB74A21936B194F325CE60C3AD367DE
#       Keygrip = 092D7C69BBE3AA5E239D09C1A8B6166FC6C5B61A

# Просмотр публичных ключей
gpg --list-keys
```

### 6. Финальная конфигурация .rpmmacros

```bash
# Оптимальная конфигурация для подписи RPM
cat > ~/.rpmmacros << 'EOF'
# Директории для сборки RPM
%_topdir /root/rpmbuild
%_sourcedir %{_topdir}/SOURCES
%_builddir %{_topdir}/BUILD
%_buildroot %{_topdir}/BUILDROOT
%_rpmdir %{_topdir}/RPMS
%_srcrpmdir %{_topdir}/SRPMS
%_specdir %{_topdir}/SPECS

# Настройки подписи GPG
%_signature gpg
%_gpg_path /root/.gnupg
%_gpg_name ABDA81F04BB74A21936B194F325CE60C3AD367DE  # Используем ID ключа
%_gpgbin /usr/bin/gpg
%_unitdir /usr/lib/systemd/system/
EOF

# Проверьте текущее значение _gpg_name
rpm -E %_gpg_name
```

### 7. Проверка полного цикла подписи

```bash
# Создайте скрипт для автоматической проверки
cat > ~/scripts/test-full-cycle.sh << 'EOF'
#!/bin/bash
set -e  # Прерывать выполнение при любой ошибке

echo "=== 1. Building RPM ==="
cd ~/scripts
rpmbuild -bb test.spec --define "_rpmdir $(pwd)"

echo "=== 2. Signing RPM ==="
rpm --addsign noarch/test-1.0-1.noarch.rpm

echo "=== 3. Importing public key ==="
# Импортируем ключ, игнорируя ошибку если уже импортирован
rpm --import /root/.gnupg/RPM-GPG-KEY-runtel 2>/dev/null || \
    gpg --export -a ABDA81F04BB74A21936B194F325CE60C3AD367DE | rpm --import -

echo "=== 4. Verifying signature ==="
rpm -Kv noarch/test-1.0-1.noarch.rpm

echo "=== 5. Key info ==="
rpm -qa | grep gpg-pubkey
EOF

# Сделайте скрипт исполняемым
chmod +x ~/scripts/test-full-cycle.sh

# Запустите проверку
~/scripts/test-full-cycle.sh
```

### 8. Устранение возможных проблем с подписью

```bash
# Если подпись не работает, проверьте:
# 1. Права доступа к GPG директории
ls -la ~/.gnupg/
# Должно быть drwx------ (700)

# 2. Наличие секретного ключа
gpg --list-secret-keys | grep -A2 "^sec"

# 3. Правильность _gpg_name в .rpmmacros
rpm -E %_gpg_name

# 4. Доступность gpg-agent
gpg-connect-agent /bye

# 5. Если используется пароль на ключ, настройте кэширование
cat > ~/.gnupg/gpg-agent.conf << EOF
allow-preset-passphrase
default-cache-ttl 3600
max-cache-ttl 86400
EOF

# Перезапустите gpg-agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent
```

<br/>
<br/>


## Интеграция с Jenkins Pipeline

### Пример Jenkinsfile с поддержкой подписи RPM

```groovy
pipeline {
    agent { label 'redos-7' }
    
    environment {
        // Указываем TTY для корректной работы GPG
        GPG_TTY = sh(script: 'tty', returnStdout: true).trim()
        // Путь к GPG
        PATH = "/usr/bin:${env.PATH}"
    }
    
    stages {
        stage('Check Environment') {
            steps {
                sh '''
                    echo "=== Проверка окружения ==="
                    java -version
                    python3 --version
                    ansible --version | head -1
                    rpm --version
                    gpg --list-secret-keys
                '''
            }
        }
        
        stage('Import GPG Key') {
            steps {
                sh '''
                    # Импортируем публичный ключ, если его нет в системе
                    if ! rpm -qa | grep -q gpg-pubkey.*3ad367de; then
                        echo "Импортируем GPG ключ в систему RPM"
                        gpg --export -a ABDA81F04BB74A21936B194F325CE60C3AD367DE | rpm --import -
                    else
                        echo "GPG ключ уже импортирован"
                    fi
                '''
            }
        }
        
        stage('Build RPMs') {
            steps {
                sh '''
                    # Сборка RPM пакетов
                    cd ${WORKSPACE}
                    rpmbuild -bb your-package.spec
                '''
            }
        }
        
        stage('Sign RPMs') {
            steps {
                sh '''
                    # Подпись всех собранных RPM
                    cd ${WORKSPACE}/rpmbuild/RPMS/x86_64/
                    for rpm in *.rpm; do
                        echo "Подписываем $rpm"
                        rpm --addsign "$rpm"
                        # Проверяем подпись
                        rpm -Kv "$rpm" | grep -q "OK" || exit 1
                    done
                    echo "Все RPM успешно подписаны"
                '''
            }
        }
    }
    
    post {
        always {
            cleanWs()  // Очистка рабочей директории
        }
    }
}
```

<br/>
<br/>


## Полезные команды для диагностики

```bash
# Проверка всех установленных GPG ключей в RPM
rpm -qa | grep gpg-pubkey | xargs rpm -qi

# Детальная информация о конкретном ключе
rpm -qi gpg-pubkey-3ad367de-5ca4b9d6

# Проверка подписи всех RPM в директории
find /path/to/rpms -name "*.rpm" -exec rpm -Kv {} \;

# Экспорт публичного ключа для распространения
gpg --export -a ABDA81F04BB74A21936B194F325CE60C3AD367DE > RPM-GPG-KEY-runtel

# Проверка, каким ключом подписан RPM
rpm -qpi package.rpm | grep Signature

# Просмотр логов gpg-agent
gpg-connect-agent "getinfo version" /bye
```

<br/>
<br/>




## Настройка Jenkins агента на Oracle Linux 9.7

Если вы используете Oracle Linux 9.7 вместо RedOS, процесс настройки имеет свои особенности. Все шаги выполняются от root.

### 1. Подключение к серверу

```bash
# Подключитесь к серверу с Oracle Linux 9.7
ssh root@<ip-адрес-сервера>

# Проверьте версию ОС
cat /etc/os-release
# Должно показать: Oracle Linux Server 9.7
```

### 2. Установка Java 17 для Jenkins агента

```bash
# Поиск доступных пакетов Java
dnf search openjdk17

# Установка Java 17
dnf install -y java-17-openjdk-devel

# Проверка установки
java -version
# Должно показать: openjdk version "17.0.x"

# Узнайте путь к Java (понадобится в настройках Jenkins)
which java
# Обычно: /usr/bin/java
```

### 3. Установка необходимых инструментов

```bash
# Установка Git и инструментов сборки
dnf install -y git make gcc gcc-c++ rpm-build rpmdevtools

# Проверка Git
git --version

# Установка Python 3 и pip
dnf install -y python3 python3-pip python3-devel

# Проверка Python
python3 --version
pip3 --version

# Установка Ansible (EPEL уже настроен в Oracle Linux 9)
dnf install -y ansible sshpass

# Проверка Ansible
ansible --version
which ansible-playbook
# Обычно: /usr/bin/ansible-playbook
```

### 4. Настройка GPG для подписи RPM

#### 4.1 Исправление прав доступа к GPG директории

```bash
# Если вы скопировали GPG ключи с другой машины
chmod 700 /root/.gnupg
chmod 600 /root/.gnupg/*

# Проверка прав
ls -la /root/.gnupg/
# Все файлы должны иметь права 600, директория 700
```

#### 4.2 Просмотр существующих GPG ключей

```bash
# Просмотр всех секретных ключей с keygrip
gpg --list-secret-keys --with-keygrip

# Пример вывода:
# sec   rsa2048 2025-09-15 [SC]
#       8410195CAB1378F5293B039239D988BC61EABBC4
#       Keygrip = 2D5821DA37178F7D5C4BD5C3DA8FB42F320DA88A
# uid         [  абсолютно ] root redos7 <support@runtel.ru>
# ssb   rsa2048 2025-09-15 [E] [   годен до: 2027-09-15]
#       Keygrip = D56BCEE6CB0B51A9287E73456706E255A205451C
#
# sec   rsa4096 2019-04-03 [SC]
#       ABDA81F04BB74A21936B194F325CE60C3AD367DE
#       Keygrip = 092D7C69BBE3AA5E239D09C1A8B6166FC6C5B61A
# uid         [  абсолютно ] runtel (RUNTEL GNUPG) <support@runtel.ru>
# ssb   rsa4096 2019-04-03 [E]
#       Keygrip = 5D767F375A4228888CF59E8BC6F9E679311A3280
```

#### 4.3 Экспорт публичного ключа

```bash
# Экспортируйте публичный ключ по ID (используйте ключ runtel)
gpg --export -a ABDA81F04BB74A21936B194F325CE60C3AD367DE > /root/.gnupg/RPM-GPG-KEY-runtel

# Проверьте содержимое
cat /root/.gnupg/RPM-GPG-KEY-runtel
# Должен отображаться блок PGP PUBLIC KEY BLOCK
```

#### 4.4 Настройка .rpmmacros для RPM

```bash
# Создайте или отредактируйте .rpmmacros
cat > /root/.rpmmacros << 'EOF'
# Директории для сборки RPM
%_topdir /root/rpmbuild
%_sourcedir %{_topdir}/SOURCES
%_builddir %{_topdir}/BUILD
%_buildroot %{_topdir}/BUILDROOT
%_rpmdir %{_topdir}/RPMS
%_srcrpmdir %{_topdir}/SRPMS
%_specdir %{_topdir}/SPECS

# Настройки подписи GPG
%_signature gpg
%_gpg_path /root/.gnupg
%_gpg_name ABDA81F04BB74A21936B194F325CE60C3AD367DE  # Используем ID ключа
%_gpgbin /usr/bin/gpg
%_unitdir /usr/lib/systemd/system/
EOF

# Проверьте конфигурацию
rpm -E %_gpg_name
# Должен вывестись ID ключа
```
```bash
# Более рабочий вариант

### ~/.rpmmacros 
#%_topdir /var/lib/jenkins/workspace/pbx_v2_redos
#%_builddir /var/lib/jenkins/workspace/pbx_v2_redos
#%_sourcedir /var/lib/jenkins/workspace/pbx_v2_redos
#%_buildroot /var/lib/jenkins/workspace/pbx_v2_redos
#%_signature gpg
#%_gpg_path /root/.gnupg
#%_gpg_name root redos7
#%_gpgbin /usr/bin/gpg2
#%_unitdir /usr/lib/systemd/system/
#%_gpg_name Jenkins RPM Signer
# Other variant
%_signature gpg
%_gpg_path /root/.gnupg
%_gpg_name ABDA81F04BB74A21936B194F325CE60C3AD367DE
%_gpgbin /usr/bin/gpg
%_unitdir /usr/lib/systemd/system/
```

### 5. Установка rpm-sign для подписи пакетов

```bash
# Установите пакет rpm-sign
dnf install -y rpm-sign

# Проверьте установку
which rpmsign
# /usr/bin/rpmsign

rpm --version
# RPM версия 4.16.1.3 или выше
```

### 6. Создание и подпись тестового RPM

#### 6.1 Создание тестового spec-файла

```bash
# Создайте директорию для тестов
mkdir -p /root/scripts
cd /root/scripts

# Создайте тестовый spec-файл
cat > test.spec << 'EOF'
Summary: Test package
Name: test
Version: 1.0
Release: 1
License: GPL
Group: Development/Tools
BuildArch: noarch

%description
Test package for RPM signing

%files
EOF
```

#### 6.2 Сборка тестового RPM

```bash
# Соберите RPM
# --define "_rpmdir $(pwd)" - сохраняет RPM в текущей директории
rpmbuild -bb test.spec --define "_rpmdir $(pwd)"

# Проверьте, что RPM создан
ls -la /root/scripts/noarch/test-1.0-1.noarch.rpm
```

#### 6.3 Подпись тестового RPM

```bash
# Подпишите RPM
rpm --addsign /root/scripts/noarch/test-1.0-1.noarch.rpm

# Команда должна выполниться без ошибок
# Если ключ защищен паролем, появится запрос на ввод
```

#### 6.4 Импорт публичного ключа в систему RPM

```bash
# Импортируйте публичный ключ
rpm --import /root/.gnupg/RPM-GPG-KEY-runtel

# Проверьте импортированные ключи
rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n'
# Должен появиться ключ: gpg-pubkey-3ad367de-xxxxxxx runtel (RUNTEL GNUPG)

# Или
rpm -qa | grep gpg-pubkey
```

#### 6.5 Проверка подписи

```bash
# Проверьте подпись RPM
rpm -Kv /root/scripts/noarch/test-1.0-1.noarch.rpm

# Ожидаемый вывод:
# /root/scripts/noarch/test-1.0-1.noarch.rpm:
#     Заголовок V4 RSA/SHA256 Signature, key ID 3ad367de: OK
#     Заголовок SHA256 digest: OK
#     Заголовок SHA1 digest: OK
#     Payload SHA256 digest: OK
#     MD5 digest: OK
```

### 7. Создание директории для Jenkins

```bash
# Создайте рабочую директорию Jenkins
mkdir -p /var/lib/jenkins/workspace

# Установите правильные права
chmod 755 /var/lib/jenkins
chmod 755 /var/lib/jenkins/workspace

# Проверьте
ls -la /var/lib/ | grep jenkins
```

### 8. Настройка .netrc для доступа к GitLab

```bash
# Создайте или отредактируйте .netrc
cat > /root/.netrc << EOF
machine gitlab.runtel.org
login jenkins
password ваш-токен-или-пароль
EOF

# Установите правильные права (обязательно!)
chmod 600 /root/.netrc

# Проверьте права
ls -la /root/.netrc
# -rw-------. 1 root root 76 мар 11 16:18 /root/.netrc
```

### 9. Проверочный скрипт для диагностики

```bash
# Создайте скрипт проверки готовности агента
cat > /root/agent-check.sh << 'EOF'
#!/bin/bash
set -e

echo "════════════════════════════════════════════"
echo "🔍 ПРОВЕРКА JENKINS АГЕНТА НА ORACLE LINUX 9"
echo "════════════════════════════════════════════"

echo -e "\n📌 СИСТЕМА:"
cat /etc/os-release | grep PRETTY_NAME

echo -e "\n📌 JAVA:"
java -version 2>&1 | head -2 || echo "❌ Java не установлена"

echo -e "\n📌 GIT:"
git --version || echo "❌ Git не установлен"

echo -e "\n📌 PYTHON:"
python3 --version || echo "❌ Python3 не установлен"
pip3 --version || echo "❌ pip3 не установлен"

echo -e "\n📌 ANSIBLE:"
ansible --version | head -2 || echo "❌ Ansible не установлен"

echo -e "\n📌 RPM:"
rpm --version | head -1

echo -e "\n📌 RPM-SIGN:"
which rpmsign || echo "❌ rpm-sign не установлен"

echo -e "\n📌 GPG КЛЮЧИ (секретные):"
gpg --list-secret-keys --with-keygrip | grep -A2 "^sec" || echo "❌ Секретные ключи не найдены"

echo -e "\n📌 GPG КЛЮЧИ В RPM:"
rpm -qa | grep gpg-pubkey || echo "❌ Ключи не импортированы в RPM"

echo -e "\n📌 ТЕСТОВЫЙ RPM:"
if [ -f /root/scripts/noarch/test-1.0-1.noarch.rpm ]; then
    echo "✅ Тестовый RPM существует"
    rpm -Kv /root/scripts/noarch/test-1.0-1.noarch.rpm | grep -E "(OK|NOKEY)"
else
    echo "❌ Тестовый RPM не найден"
fi

echo -e "\n📌 ДИРЕКТОРИЯ JENKINS:"
ls -la /var/lib/jenkins/ | head -5

echo -e "\n📌 .NETRC:"
ls -la /root/.netrc
if [ -f /root/.netrc ]; then
    echo "✅ .netrc существует, права: $(stat -c %a /root/.netrc)"
else
    echo "❌ .netrc не найден"
fi

echo -e "\n════════════════════════════════════════════"
echo "✅ ПРОВЕРКА ЗАВЕРШЕНА"
echo "════════════════════════════════════════════"
EOF

# Сделайте скрипт исполняемым
chmod +x /root/agent-check.sh

# Запустите проверку
/root/agent-check.sh
```

### 10. Настройка Jenkins агента в веб-интерфейсе

При создании/настройке ноды в Jenkins укажите:

- **Имя ноды**: `oracle9-7` (или любое удобное)
- **Remote root directory**: `/var/lib/jenkins`
- **Метки**: `oracle9 oraclelinux9`
- **Launch method**: `Launch agents via SSH`
- **Host**: IP-адрес вашего сервера
- **Credentials**: Добавьте SSH ключ или пароль root
- **Host Key Verification Strategy**: `Non verifying Verification Strategy`
- **Java Path**: `/usr/bin/java` (или путь из `which java`)
- **Availability**: `Keep this agent online as much as possible`

### 11. Полный цикл проверки подписи

```bash
# Создайте скрипт для полного цикла
cat > /root/scripts/test-full-cycle.sh << 'EOF'
#!/bin/bash
set -e

echo "════════════════════════════════════════════"
echo "🔄 ПОЛНЫЙ ЦИКЛ ПРОВЕРКИ ПОДПИСИ RPM"
echo "════════════════════════════════════════════"

echo -e "\n📦 1. СБОРКА ТЕСТОВОГО RPM"
cd /root/scripts
rpmbuild -bb test.spec --define "_rpmdir $(pwd)" > /dev/null
echo "✅ RPM собран: /root/scripts/noarch/test-1.0-1.noarch.rpm"

echo -e "\n✍️ 2. ПОДПИСЬ RPM"
rpm --addsign /root/scripts/noarch/test-1.0-1.noarch.rpm
echo "✅ RPM подписан"

echo -e "\n🔑 3. ИМПОРТ ПУБЛИЧНОГО КЛЮЧА"
rpm --import /root/.gnupg/RPM-GPG-KEY-runtel 2>/dev/null || \
    gpg --export -a ABDA81F04BB74A21936B194F325CE60C3AD367DE | rpm --import -
echo "✅ Ключ импортирован"

echo -e "\n🔍 4. ПРОВЕРКА ПОДПИСИ"
rpm -Kv /root/scripts/noarch/test-1.0-1.noarch.rpm

echo -e "\n📋 5. КЛЮЧИ В СИСТЕМЕ"
rpm -qa | grep gpg-pubkey | tail -1

echo -e "\n════════════════════════════════════════════"
echo "✅ ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ"
echo "════════════════════════════════════════════"
EOF

chmod +x /root/scripts/test-full-cycle.sh
/root/scripts/test-full-cycle.sh
```

### 12. Отличия Oracle Linux 9 от RedOS 7.3.6

| Параметр | RedOS 7.3.6 | Oracle Linux 9.7 |
|----------|-------------|------------------|
| **Пакетный менеджер** | `yum` | `dnf` (совместим с yum) |
| **Java по умолчанию** | Java 8 или 11 | Java 11 или 17 |
| **Python** | Python 2.7 + Python 3.6 | Python 3.9+ |
| **Ansible** | Требует EPEL | Доступен в EPEL |
| **RPM версия** | 4.11.x | 4.16.x |
| **Systemd** | Версия 219 | Версия 252+ |

### 13. Возможные проблемы и решения

#### Проблема: "gpg: Внимание: небезопасные права доступа к домашнему каталогу '/root/.gnupg'"

```bash
# Решение: исправьте права
chmod 700 /root/.gnupg
chmod 600 /root/.gnupg/*
```

#### Проблема: RPM подписан, но проверка показывает "NOKEY"

```bash
# Решение: импортируйте публичный ключ
rpm --import /root/.gnupg/RPM-GPG-KEY-runtel
```

#### Проблема: "Ошибка открытия: Нет такого файла или каталога" при подписи

```bash
# Решение: проверьте правильность пути
ls -la /path/to/your.rpm
# Используйте абсолютный путь
rpm --addsign /полный/абсолютный/путь/до/файла.rpm
```

### 14. Готовые метки для Jenkins

При настройке ноды рекомендуется добавить следующие метки (labels):
- `oracle9`
- `oracle-linux-9`
- `rpm-builder`
- `gpg-signer`

Это позволит в Jenkinsfile указывать:
```groovy
agent { label 'oracle9 && rpm-builder' }
```

<br/>
<br/>





## Заключение

После выполнения всех шагов у вас будет полностью настроенный Jenkins агент на RedOS 7.3.6 с возможностью:
- Сборки RPM пакетов
- Подписи RPM с использованием GPG
- Проверки подписей
- Интеграции с Ansible для деплоя
- Работы с Git-репозиториями

**Ключевые моменты для проверки:**
1. Java 17+ установлена и доступна
2. GPG ключи имеют статус "абсолютно" (доверие установлено)
3. Публичный ключ импортирован в систему RPM
4. .rpmmacros настроен с правильным ID ключа
5. Тестовый RPM успешно подписывается и проверяется

Теперь ваш агент готов к работе в Jenkins!
