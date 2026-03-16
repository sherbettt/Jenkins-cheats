Создан override файл **/etc/systemd/system/jenkins.service.d/proxy.conf** с содержимым:
```bash
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Dhttp.proxyHost=5.45.127.22 -Dhttp.proxyPort=1080 -Dhttps.proxyHost=5.45.127.22 -Dhttps.proxyPort=1080 -Dhttp.proxyUser=proxyuser -Dhttp.proxyPassword=RuntelProxy36 -Dhttp.nonProxyHosts=localhost\\|127.0.0.1\\|192.168.*\\|sso.runtel.ru -Djdk.http.auth.tunneling.disabledSchemes= -Djdk.http.auth.proxying.disabledSchemes= -Dhttps.protocols=TLSv1.2,TLSv1.3" 
/etc/system
```

Т.к. переопределение переменной JAVA_ARGS в /etc/default/jenkins не помогло
```bash
root@jenkins-updated /etc/systemd/system/jenkins.service.d > ccat /etc/default/jenkins | grep JAVA_ARGS
#JAVA_ARGS="-Djava.awt.headless=true"
JAVA_ARGS="-Djava.awt.headless=true -Dhttp.proxyHost=5.45.127.22 -Dhttp.proxyPort=1080 -Dhttps.proxyHost=5.45.127.22 -Dhttps.proxyPort=1080 -Dhttp.nonProxyHosts='localhost|127.0.0.1'"
#JAVA_ARGS="-Djava.awt.headless=true -Dhttp.proxyHost=5.45.127.22 -Dhttp.proxyPort=1080 -Dhttp.proxyUser=proxyuser -Dhttp.proxyPassword=RuntelProxy36 -Dhttps.proxyHost=5.45.127.22 -Dhttps.proxyPort=1080 -Dhttps.proxyUser=AaAaAaA -Dhttps.proxyPassword=BbBbBbCcCcC -Dhttp.nonProxyHosts='localhost|127.0.0.1' -Djdk.http.auth.tunneling.disabledSchemes= -Djdk.http.auth.proxying.disabledSchemes="
#JAVA_ARGS="-Xmx256m"
#JAVA_ARGS="-Djava.net.preferIPv4Stack=true"
```



<!-- 
```bash
root@jenkins-updated /etc/systemd/system/jenkins.service.d > ccat /etc/default/jenkins | grep JAVA_ARGS
#JAVA_ARGS="-Djava.awt.headless=true"
JAVA_ARGS="-Djava.awt.headless=true -Dhttp.proxyHost=5.45.127.22 -Dhttp.proxyPort=1080 -Dhttps.proxyHost=5.45.127.22 -Dhttps.proxyPort=1080 -Dhttp.nonProxyHosts='localhost|127.0.0.1'"
#JAVA_ARGS="-Djava.awt.headless=true -Dhttp.proxyHost=5.45.127.22 -Dhttp.proxyPort=1080 -Dhttp.proxyUser=proxyuser -Dhttp.proxyPassword=RuntelProxy36 -Dhttps.proxyHost=5.45.127.22 -Dhttps.proxyPort=1080 -Dhttps.proxyUser=proxyuser -Dhttps.proxyPassword=RuntelProxy36 -Dhttp.nonProxyHosts='localhost|127.0.0.1' -Djdk.http.auth.tunneling.disabledSchemes= -Djdk.http.auth.proxying.disabledSchemes="
#JAVA_ARGS="-Xmx256m"
#JAVA_ARGS="-Djava.net.preferIPv4Stack=true"
-->

-----------------------
<br/>



### **Этап 1: Проверка базовой связности**
Сначала мы убедились, что прокси-сервер вообще доступен:
```bash
ping 5.45.127.22        # Хост отвечает? Да, 25ms
nc -zv 5.45.127.22 1080 # Порт открыт? Да, "socks open"
```
Так мы узнали, что прокси — **SOCKS5**, а не HTTP.

### **Этап 2: Проверка работы прокси из командной строки**
Пробовали разные типы подключения через `curl`:
```bash
# HTTP прокси (не работает)
curl -x http://proxyuser:pass@5.45.127.22:1080 https://google.com → "Proxy CONNECT aborted"

# SOCKS5 без авторизации (не работает)
curl --socks5 5.45.127.22:1080 https://google.com → "No authentication method was acceptable"

# SOCKS5 с авторизацией (РАБОТАЕТ!)
curl --socks5 5.45.127.22:1080 --proxy-user proxyuser:pass https://google.com → Успех!
```
**Вывод:** прокси работает, но только как SOCKS5 с авторизацией.

### **Этап 3: Проверка доступности SSO-провайдера**
Заглянули в конфиг Jenkins и нашли URL OpenID провайдера:
```bash
grep -A 20 "OicSecurityRealm" /var/lib/jenkins/config.xml
```
Увидели: `https://sso.runtel.ru:8443/realms/runtel/.well-known/openid-configuration`

Проверили доступность SSO через прокси:
```bash
curl --socks5 ... https://sso.runtel.ru:8443/... → ЗАВИСЛО!
```
**Важное открытие:** `sso.runtel.ru` резолвится во **внутренний IP 192.168.87.2**.

### **Этап 4: Проверка прямого доступа к SSO**
Отключили прокси и проверили напрямую с сервера Jenkins:
```bash
curl -v https://sso.runtel.ru:8443/...
```
**Результат:** Мгновенный ответ, JSON с конфигурацией, валидный SSL-сертификат.
**Вывод:** SSO доступен напрямую, проблема именно в маршрутизации через прокси.

### **Этап 5: Исследование механизмов Java**
Вспомнили документацию Oracle:
- SOCKS прокси (`-DsocksProxyHost`) работает на уровне TCP-соединений и **игнорирует** `http.nonProxyHosts`
- HTTP прокси (`-Dhttp.proxyHost`) уважает список исключений

### **Этап 6: Проверка работы systemd**
Обнаружили, что `JAVA_ARGS` в `/etc/default/jenkins` **не применяются**:
```bash
ps aux | grep java | grep proxy # пусто
systemctl show jenkins | grep Environment # видно только базовые переменные
```
**Вывод:** в вашей версии Jenkins параметры нужно передавать через systemd override.

### **Этап 7: Эксперимент с исключениями**
Создали override-файл, добавили SSO в `nonProxyHosts`, но SOCKS продолжал игнорировать исключения.

### **Этап 8: Финальное решение**
Переключились с SOCKS на HTTP прокси и добавили все внутренние адреса в исключения:
```ini
-Dhttp.proxyHost=5.45.127.22 -Dhttp.proxyPort=1080
-Dhttp.nonProxyHosts=localhost\\|127.0.0.1\\|192.168.*\\|sso.runtel.ru
```

### **Этап 9: Проверка результата**
После перезапуска Jenkins:
1. Вход через SSO заработал
2. Telegram-уведомления пошли
3. `ps aux | grep java` показал все параметры

## **Ключевые инсайты, которые мы получили**

1. **Прокси бывают разные** — SOCKS и HTTP ведут себя принципиально по-разному
2. **DNS может обманывать** — `sso.runtel.ru` оказался внутри сети, хотя имя "внешнее"
3. **Инструменты диагностики** — `curl`, `nc`, `ps`, `systemctl` — наши лучшие друзья
4. **Документация важна** — знание того, как Java обрабатывает разные типы прокси, сэкономило часы
5. **Systemd диктует правила** — в современных системах нужно знать, где действительно лежат конфиги


