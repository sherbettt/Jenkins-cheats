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
#JAVA_ARGS="-Djava.awt.headless=true -Dhttp.proxyHost=5.45.127.22 -Dhttp.proxyPort=1080 -Dhttp.proxyUser=proxyuser -Dhttp.proxyPassword=RuntelProxy36 -Dhttps.proxyHost=5.45.127.22 -Dhttps.proxyPort=1080 -Dhttps.proxyUser=proxyuser -Dhttps.proxyPassword=RuntelProxy36 -Dhttp.nonProxyHosts='localhost|127.0.0.1' -Djdk.http.auth.tunneling.disabledSchemes= -Djdk.http.auth.proxying.disabledSchemes="
#JAVA_ARGS="-Xmx256m"
#JAVA_ARGS="-Djava.net.preferIPv4Stack=true"
```

-----------------------
<br/>



