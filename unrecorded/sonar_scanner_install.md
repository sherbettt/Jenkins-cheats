# Процесс установки SonarScanner CLI

## 1. Скачивание
Перейдите на официальную страницу загрузки SonarScanner:
https://binaries.sonarsource.com/?prefix=Distribution/sonar-scanner-cli/
https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/

Выберите нужную версию (рекомендуется последняя стабильная). Для Linux x64 скачайте архив с суффиксом `-linux-x64.zip`.

Пример команды скачивания через wget:
```bash
cd /tmp
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.2.0.4584-linux-x64.zip
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-8.0.1.6346.zip
```

## 2. Распаковка
Распакуйте архив в директорию `/opt`:
```bash
sudo unzip sonar-scanner-cli-6.2.0.4584-linux-x64.zip -d /opt
```

Проверьте содержимое:
```bash
ls -la /opt/sonar-scanner-6.2.0.4584-linux-x64/
```

## 3. Настройка PATH
### Вариант A: Симлинк в /usr/local/bin
```bash
sudo ln -s /opt/sonar-scanner-6.2.0.4584-linux-x64/bin/sonar-scanner /usr/local/bin/sonar-scanner
```

### Вариант B: Добавление в PATH через профиль
Создайте файл `/etc/profile.d/sonar-scanner.sh`:
```bash
echo 'export PATH=/opt/sonar-scanner-6.2.0.4584-linux-x64/bin:$PATH' | sudo tee /etc/profile.d/sonar-scanner.sh
```

Примените изменения в текущей сессии:
```bash
source /etc/profile.d/sonar-scanner.sh
```

## 4. Проверка установки
```bash
which sonar-scanner
sonar-scanner --version
```

Ожидаемый вывод:
```
sonar-scanner является /opt/sonar-scanner-6.2.0.4584-linux-x64/bin/sonar-scanner
08:32:04.704 INFO  Scanner configuration file: /opt/sonar-scanner-6.2.0.4584-linux-x64/conf/sonar-scanner.properties
08:32:04.706 INFO  Project root configuration file: NONE
08:32:04.715 INFO  SonarScanner CLI 6.2.0.4584
08:32:04.716 INFO  Java 17.0.12 Eclipse Adoptium (64-bit)
08:32:04.716 INFO  Linux 6.8.12-20-pve amd64
```

## 5. Настройка для Jenkins
Если Jenkins работает на том же сервере, sonar-scanner будет доступен автоматически. Если Jenkins agent запущен в контейнере, нужно:
- Установить sonar-scanner внутри контейнера
- Или смонтировать директорию `/opt/sonar-scanner-6.2.0.4584-linux-x64` как volume

## 6. Использование в Jenkins pipeline
Stage в JenkinsFile:
```groovy
stage('SonarQube Analysis') {
    steps {
        sh 'sonar-scanner -X -Dsonar.projectKey=your_project_key'
    }
}
```

## 7. Возможные проблемы и решения
- **"команда не найдена"**: Проверьте PATH и симлинки.
- **Ошибка Java**: Убедитесь, что Java установлена (требуется Java 11+).
- **Права доступа**: Убедитесь, что у пользователя Jenkins есть права на выполнение sonar-scanner.

## 8. Дополнительная настройка
При необходимости отредактируйте конфигурационный файл:
```bash
nano /opt/sonar-scanner-6.2.0.4584-linux-x64/conf/sonar-scanner.properties
```

Установка завершена. Теперь sonar-scanner готов к использованию в CI/CD.