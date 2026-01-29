# Инструкция: Диагностика и решение проблемы `Failed to create a temporary` с Jenkins

## Проблема
Jenkins выдавал ошибку:
```
java.io.IOException: Failed to create a temporary file in /var/lib/jenkins/jobs/runtelpbx_eapi_liga/indexing
```

## Последовательность диагностики

### 1. Первичная проверка статуса Jenkins
```bash
systemctl status jenkins.service -l --no-pager
```
**Результат**: Сервис активен, но есть ошибки создания временных файлов

### 2. Проверка прав доступа и места на диске
```bash
ll /var/lib/jenkins/jobs/runtelpbx_eapi_liga/indexing
df -h /var/lib/jenkins/
df -h
```
**Результат**: Права доступа корректные, места на диске достаточно (66G свободно)

### 3. Проверка inodes (ключевая диагностика)
```bash
df -i /var/lib/jenkins/
sudo -u jenkins touch /var/lib/jenkins/jobs/runtelpbx_eapi_liga/indexing/test.tmp
```
**Результат**: 
- Inodes использованы на **100%** (7208960/7208960)
- Нельзя создать временные файлы - "No space left on device"

### 4. Поиск источника проблемы
```bash
# Поиск директорий с наибольшим количеством файлов
sudo find / -xdev -type f | cut -d "/" -f 2 | sort | uniq -c | sort -nr | head -20
sudo find / -mount -type f | awk -F/ 'NF<=3{print $2} NF>3{print $3}' | sort | uniq -c | sort -rn | head -10

# Проверка файлов в Jenkins
find /var/lib/jenkins/ -type f | wc -l
```
**Результат**: 
- 7,002,414 файлов в `/var`
- 6,996,048 файлов в `/var/lib/jenkins/`

### 5. Детальный анализ структуры Jenkins
```bash
# Анализ по директориям внутри Jenkins
sudo find /var/lib/jenkins -type f | awk -F/ '{print $5}' | sort | uniq -c | sort -rn | head -20

# Поиск проблемных job'ов
for job in /var/lib/jenkins/jobs/*; do
    count=$(sudo find "$job" -type f | wc -l)
    echo "$count - $job"
done | sort -rn | head -10
```
**Результат**: Job `pbx_v2_deb11_dev60` создал **6,573,518 файлов**

### 6. Очистка временных файлов системы
```bash
# Быстрая очистка системных временных файлов
find /var/tmp -type f -name "*.tmp" -delete
find /tmp -type f -name "*.tmp" -delete
find /var/log -name "*.log.*" -type f -mtime +7 -delete
find /var/log -name "*.gz" -type f -delete
apt-get clean
```
**Результат**: Inodes освобождены до 92% использования

### 7. Очистка старых сборок Jenkins
```bash
# Остановка Jenkins
sudo systemctl stop jenkins

# Удаление старых сборок (оставить последние 50)
find /var/lib/jenkins/jobs/pbx_v2_deb11_dev60/builds -mindepth 1 -maxdepth 1 -type d | sort -rn | tail -n +51 | xargs sudo rm -rf

# Проверка результатов
df -i /
find /var/lib/jenkins/ -type f | wc -l
```
**Результат**: 
- Inodes: с 100% до 30% использования
- Файлов в Jenkins: с ~7M до 2.1M
- Файлов в проблемной job'е: с 6.5M до 1.7M

### 8. Посмотрим что занимает место в оставшихся build'ах
```bash
for build in /var/lib/jenkins/jobs/pbx_v2_deb11_dev60/builds/*/; do
    file_count=$(sudo find "$build" -type f | wc -l)
    size=$(sudo du -sh "$build" 2>/dev/null | cut -f1)
    echo "Build $(basename $build): $file_count files, $size"
done | sort -k2 -rn | head -10
```
```bash
# Посмотрим какие поддиректории создают больше всего файлов
sudo find /var/lib/jenkins/jobs/pbx_v2_deb11_dev60/builds/ -type f | awk -F/ '{if(NF>=8) print $7}' | sort | uniq -c | sort -rn | head -10
```
```bash
# Оставить только последние 20 сборок (вместо 50)
sudo find /var/lib/jenkins/jobs/pbx_v2_deb11_dev60/builds -mindepth 1 -maxdepth 1 -type d | sort -rn | tail -n +21 | xargs sudo rm -rf

# Проверим результат
echo "Files after cleanup: $(find /var/lib/jenkins/jobs/pbx_v2_deb11_dev60/ -type f | wc -l)"
df -i /
```

----------
<br/>


# Автоочистка билдов

Есть несколько способов настройки автоочистки, от лучшего к простому:

## 1. **Нативный способ Jenkins (Рекомендуется)**

### В веб-интерфейсе Jenkins:
1. Перейдите в job → **Configure**
2. Секция **"Discard old builds"**
3. Настройте параметры:
   - **Days to keep builds**: 7-14
   - **Max # of builds to keep**: 10-20
   - **Artifacts days to keep**: 7
   - **Artifacts number to keep**: 5

### Через Groovy скрипт (глобальная настройка):
```bash
# В Manage Jenkins → Script Console
Jenkins.instance.getAllItems(AbstractProject.class).each { job ->
    if (job.buildDiscarder == null) {
        job.buildDiscarder = new hudson.tasks.LogRotator(
            10,     // daysToKeep
            20,     // numToKeep
            5,      // artifactDaysToKeep
            5       // artifactNumToKeep
        )
    }
}
```

## 2. **Через Jenkins CLI/API**

### Скрипт для очистки старых сборок:
```bash
#!/bin/bash
# cleanup_jenkins.sh

JENKINS_URL="http://localhost:8080"
JENKINS_USER="username"
JENKINS_TOKEN="token"

# Очистка старых сборок для всех job'ов
java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USER:$JENKINS_TOKEN list-jobs | while read job; do
    echo "Cleaning up old builds for $job"
    java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USER:$JENKINS_TOKEN delete-builds "$job" 1-1000
done
```

## 3. **Через файловую систему + Cron**

### Скрипт для cron:
```bash
#!/bin/bash
# /usr/local/bin/jenkins_cleanup.sh

# Остановить Jenkins перед очисткой
sudo systemctl stop jenkins

# Очистка старых сборок (оставить последние 20)
for job_dir in /var/lib/jenkins/jobs/*/builds; do
    if [ -d "$job_dir" ]; then
        echo "Cleaning $job_dir"
        find "$job_dir" -mindepth 1 -maxdepth 1 -type d | sort -rn | tail -n +21 | xargs rm -rf
    fi
done

# Очистка workspace (опционально)
find /var/lib/jenkins/workspace -name "*.tmp" -type f -mtime +1 -delete

# Запустить Jenkins обратно
sudo systemctl start jenkins

# Логирование
echo "$(date): Jenkins cleanup completed" >> /var/log/jenkins_cleanup.log
```

### Добавить в cron:
```bash
# Редактировать crontab
sudo crontab -e

# Добавить (запуск каждое воскресенье в 2:00)
0 2 * * 0 /usr/local/bin/jenkins_cleanup.sh

# Или ежедневно в 3:00
0 3 * * * /usr/local/bin/jenkins_cleanup.sh
```

## 4. **Использование Jenkins Plugin**

Установите плагины:
- **ThinBackup** - для бэкапов и очистки
- **Job Configuration History** - для управления конфигурациями
- **Workspace Cleanup Plugin** - для очистки workspace

## 5. **Комбинированное решение (Рекомендуется)**

```bash
#!/bin/bash
# /usr/local/bin/jenkins_maintenance.sh

JENKINS_HOME="/var/lib/jenkins"
LOG_FILE="/var/log/jenkins_maintenance.log"

echo "$(date): Starting Jenkins maintenance" >> $LOG_FILE

# 1. Остановить Jenkins
sudo systemctl stop jenkins

# 2. Очистка сборок (оставить последние 15)
for job in $JENKINS_HOME/jobs/*; do
    if [ -d "$job/builds" ]; then
        build_count=$(find "$job/builds" -maxdepth 1 -type d -name "[0-9]*" | wc -l)
        if [ $build_count -gt 15 ]; then
            echo "Cleaning $job - removing $((build_count - 15)) old builds" >> $LOG_FILE
            find "$job/builds" -mindepth 1 -maxdepth 1 -type d | sort -rn | tail -n +16 | xargs rm -rf
        fi
    fi
done

# 3. Очистка временных файлов
find $JENKINS_HOME -name "*.tmp" -type f -mtime +1 -delete
find $JENKINS_HOME -name "*.log" -type f -mtime +30 -delete

# 4. Запустить Jenkins
sudo systemctl start jenkins

# 5. Проверить статус
if systemctl is-active --quiet jenkins; then
    echo "$(date): Jenkins maintenance completed successfully" >> $LOG_FILE
else
    echo "$(date): ERROR: Jenkins failed to start" >> $LOG_FILE
fi

# 6. Проверить inodes
echo "$(date): Inodes usage: $(df -i / | awk 'NR==2 {print $5}')" >> $LOG_FILE
```

## **Рекомендация:**

**Лучший вариант**: Использовать нативный способ Jenkins + ThinBackup plugin  
**Быстрое решение**: Скрипт через cron (вариант 5) с запуском раз в неделю

Для cron настройки:
```bash
# Делаем скрипт исполняемым
sudo chmod +x /usr/local/bin/jenkins_maintenance.sh

# Добавляем в cron (каждое воскресенье в 2:00)
echo "0 2 * * 0 /usr/local/bin/jenkins_maintenance.sh" | sudo crontab -
```

## Мониторинг
Для мониторинга можно добавить простую проверку в cron:
```bash
crontab -e
## добавляем
# Ежедневная проверка inodes
0 8 * * * echo "$(date): Inodes usage: $(df -i / | awk 'NR==2 {print $5}')" >> /var/log/inodes_check.log
```
