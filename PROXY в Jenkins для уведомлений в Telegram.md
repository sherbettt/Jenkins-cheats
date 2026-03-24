# Настройка прокси для Jenkins: полное руководство

## Проблема
Jenkins не может подключиться к внешним ресурсам (SSO, Telegram, обновления плагинов) при работе через корпоративный прокси-сервер. После первоначальной настройки SSO и Telegram заработали, но установка плагинов продолжала падать с ошибкой `Unexpected end of file from server`.

---

## Финальное рабочее решение

Создан override файл **/etc/systemd/system/jenkins.service.d/proxy.conf** с итоговым содержимым:

```bash
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Dhttp.proxyHost=5.45.127.22 -Dhttp.proxyPort=1080 -Dhttps.proxyHost=5.45.127.22 -Dhttps.proxyPort=1080 -Dhttp.proxyUser=proxyuser -Dhttp.proxyPassword=RuntelProxy36 -Dhttp.nonProxyHosts=localhost\\|127.0.0.1\\|192.168.*\\|sso.runtel.ru\\|updates.jenkins.io\\|*.jenkins.io\\|mirrors.jenkins.io\\|mirror.yandex.ru -Djdk.http.auth.tunneling.disabledSchemes= -Djdk.http.auth.proxying.disabledSchemes= -Dhttps.protocols=TLSv1.2,TLSv1.3"
```

Вариант А: Убрать mirror.yandex.ru из исключений, но добавить другие параметры:
```bash
[Service]
Environment="JAVA_OPTS=-Dhttp.proxyHost=5.45.127.22 -Dhttp.proxyPort=1080 -Dhttps.proxyHost=5.45.127.22 -Dhttps.proxyPort=1080 -Dhttp.proxyUser=proxyuser -Dhttp.proxyPassword=RuntelProxy36 -Dhttp.nonProxyHosts=localhost\\|127.0.0.1\\|192.168.*\\|sso.runtel.ru\\|updates.jenkins.io\\|*.jenkins.io\\|mirrors.jenkins.io -Djdk.http.auth.tunneling.disabledSchemes= -Djdk.http.auth.proxying.disabledSchemes= -Dhttps.protocols=TLSv1.2,TLSv1.3"
```


Вариант Б: Использовать SOCKS5 прокси вместо HTTP:
```bash
[Service]
Environment="JAVA_OPTS=-DsocksProxyHost=5.45.127.22 -DsocksProxyPort=1080 -Djava.net.socks.username=proxyuser -Djava.net.socks.password=RuntelProxy36"
```

### Альтернативное решение

Вместо добавления ***`mirror.yandex.ru`*** в исключения, можно настроить Jenkins использовать другое зеркало: **`https://updates.jenkins.io/update-center.json`**

Или создайте файл /var/lib/jenkins/hudson.model.UpdateCenter.xml:
```xml
<?xml version='1.1' encoding='UTF-8'?>
<sites>
  <site>
    <id>default</id>
    <url>https://mirrors.huaweicloud.com/jenkins/updates/update-center.json</url>
  </site>
</sites>
```

---

## Эволюция конфигурации: от ошибок к успеху

### **Попытка 1: Базовая настройка (неудачно)**
```bash
-Dhttp.proxyHost=5.45.127.22 -Dhttp.proxyPort=1080
-Dhttp.nonProxyHosts=localhost|127.0.0.1
```
**Результат:** SSO не работает, Telegram не работает.  
**Причина:** Внутренние адреса (sso.runtel.ru) не добавлены в исключения, запросы уходят через прокси и зависают.

---

### **Попытка 2: Добавление SSO в исключения (частичный успех)**
```bash
-Dhttp.nonProxyHosts=localhost|127.0.0.1|192.168.*|sso.runtel.ru
```
**Результат:** ✅ SSO заработал, ✅ Telegram заработал.  
**Причина:** Внутренние ресурсы теперь ходят напрямую, минуя прокси.

---

### **Попытка 3: Обновления плагинов (новая ошибка)**
При установке плагинов возникла ошибка:
```
java.net.SocketException: Unexpected end of file from server
Failed to download from https://updates.jenkins.io/download/plugins/... 
→ https://mirror.yandex.ru/mirrors/jenkins/plugins/...
```
**Результат:** ❌ Плагины не устанавливаются.  
**Причина:** Jenkins получает список обновлений через прокси, но при скачивании происходит редирект на зеркало `mirror.yandex.ru`. HTTP-прокси не может корректно обработать SSL-туннель к этому зеркалу.

---

### **Попытка 4: Добавление доменов Jenkins в исключения (недостаточно)**
```bash
-Dhttp.nonProxyHosts=...|updates.jenkins.io|*.jenkins.io|mirrors.jenkins.io
```
**Результат:** ❌ Плагины все еще не устанавливаются.  
**Причина:** Редирект ведет на конкретное зеркало `mirror.yandex.ru`, которое не было в исключениях.

---

### **Финальное решение: добавление зеркала в исключения (УСПЕХ!)**
```bash
-Dhttp.nonProxyHosts=...|mirror.yandex.ru
```
**Результат:** ✅ Плагины успешно скачиваются и устанавливаются.  
**Почему заработало:** Зеркало `mirror.yandex.ru` добавлено в список исключений, поэтому Jenkins подключается к нему напрямую, минуя проблемный прокси. При этом список обновлений по-прежнему получается через прокси (это работает корректно).

---

## Полная диагностика и поиск решения

### **Этап 1: Проверка базовой связности**
```bash
ping 5.45.127.22        # Хост отвечает? Да, 25ms
nc -zv 5.45.127.22 1080 # Порт открыт? Да, "socks open"
```
**Вывод:** прокси работает, но идентифицирован как **SOCKS5**, а не HTTP.

### **Этап 2: Проверка работы прокси из командной строки**
```bash
# HTTP прокси (не работает)
curl -x http://proxyuser:pass@5.45.127.22:1080 https://google.com → "Proxy CONNECT aborted"

# SOCKS5 без авторизации (не работает)
curl --socks5 5.45.127.22:1080 https://google.com → "No authentication method was acceptable"

# SOCKS5 с авторизацией (РАБОТАЕТ!)
curl --socks5 5.45.127.22:1080 --proxy-user proxyuser:pass https://google.com → Успех!
```
**Вывод:** прокси работает как SOCKS5 с авторизацией.

### **Этап 3: Проверка доступности SSO-провайдера**
```bash
grep -A 20 "OicSecurityRealm" /var/lib/jenkins/config.xml
# Найден URL: https://sso.runtel.ru:8443/realms/runtel/.well-known/openid-configuration

curl --socks5 ... https://sso.runtel.ru:8443/... → ЗАВИСЛО!
```
**Важное открытие:** `sso.runtel.ru` резолвится во **внутренний IP 192.168.87.2**.

### **Этап 4: Проверка прямого доступа к SSO**
```bash
curl -v https://sso.runtel.ru:8443/... # Мгновенный ответ, JSON с конфигурацией
```
**Вывод:** SSO доступен напрямую, проблема в маршрутизации через прокси.

### **Этап 5: Исследование механизмов Java**
- SOCKS прокси (`-DsocksProxyHost`) игнорирует `http.nonProxyHosts`
- HTTP прокси (`-Dhttp.proxyHost`) уважает список исключений

**Вывод:** используем HTTP прокси для поддержки исключений.

### **Этап 6: Проверка работы systemd**
```bash
ps aux | grep java | grep proxy # пусто
systemctl show jenkins | grep Environment # видно только базовые переменные
```
**Вывод:** параметры нужно передавать через systemd override, `/etc/default/jenkins` не применяется.

### **Этап 7: Диагностика ошибки скачивания плагинов**
Ошибка в логах:
```
Failed to download from https://updates.jenkins.io/download/plugins/... 
→ https://mirror.yandex.ru/mirrors/jenkins/plugins/...
java.net.SocketException: Unexpected end of file from server
```
**Вывод:** Jenkins получает список обновлений (через прокси), но при скачивании происходит редирект на зеркало `mirror.yandex.ru`. HTTP-прокси не может корректно обработать SSL-туннель к этому зеркалу.

### **Этап 8: Финальное решение**
Добавили зеркало `mirror.yandex.ru` в исключения:
```ini
-Dhttp.nonProxyHosts=...|mirror.yandex.ru
```

### **Этап 9: Проверка результата**
```bash
systemctl daemon-reload
systemctl restart jenkins
ps aux | grep java | grep nonProxyHosts
# Параметры применились, в списке исключений появился mirror.yandex.ru
```

В интерфейсе Jenkins:
```
Build Pipeline      Downloaded Successfully. Will be activated during the next boot
Chocolate Theme     Downloaded Successfully. Will be activated during the next boot
ChuckNorris         Downloaded Successfully. Will be activated during the next boot
```

---

## Ключевые инсайты

1. **Прокси бывают разные** — SOCKS и HTTP ведут себя принципиально по-разному
2. **DNS может обманывать** — `sso.runtel.ru` оказался внутри сети, хотя имя "внешнее"
3. **Инструменты диагностики** — `curl`, `nc`, `ps`, `systemctl` — наши лучшие друзья
4. **Документация важна** — знание того, как Java обрабатывает разные типы прокси, сэкономило часы
5. **Systemd диктует правила** — в современных системах нужно знать, где действительно лежат конфиги
6. **Исключения критичны** — для обновлений плагинов нужно добавить не только `updates.jenkins.io`, но и **конкретные зеркала** (например, `mirror.yandex.ru`), на которые происходит редирект
7. **Редиректы — ловушка** — Jenkins может получать список обновлений через прокси, но скачивать файлы с другого хоста (зеркала), который тоже нужно добавлять в исключения

---

## Применение изменений

```bash
# 1. Создать/отредактировать override файл
mcedit /etc/systemd/system/jenkins.service.d/proxy.conf

# 2. Перезагрузить конфигурацию systemd
systemctl daemon-reload

# 3. Перезапустить Jenkins
systemctl restart jenkins.service

# 4. Проверить, что параметры применились
ps aux | grep java | grep nonProxyHosts

# 5. Проверить статус
systemctl status jenkins.service -l --no-pager
```

---

## Итог

Проблема решена путем:
- Использования **HTTP прокси** вместо SOCKS (для поддержки `nonProxyHosts`)
- Добавления **всех внутренних адресов** (`192.168.*`, `sso.runtel.ru`) в исключения
- Добавления **доменов Jenkins** (`updates.jenkins.io`, `*.jenkins.io`, `mirrors.jenkins.io`) в исключения
- Добавления **конкретного зеркала** (`mirror.yandex.ru`), на которое происходит редирект при скачивании плагинов

Jenkins теперь успешно работает через прокси:
- ✅ Вход через SSO
- ✅ Telegram-уведомления
- ✅ Получение списка обновлений
- ✅ Скачивание и установка плагинов


