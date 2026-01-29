## Зайти на Master ноду Jenkins
API: https://jenkins.runtel.ru/view/v2/job/BUILD_BACK/1801/artifact/vulnerabilities/

Найдём артефакты анализа уязвимостей для проекта `https://jenkins.runtel.ru/view/v2/job/BUILD_BACK/` :
```bash
kkorablin@jenkins-updated:~$ sudo find /var/lib/jenkins/jobs/BUILD_BACK/builds/1801/ -name "*.json" -type f
/var/lib/jenkins/jobs/BUILD_BACK/builds/1801/archive/vulnerabilities/vulnerabilities_trivy.json
/var/lib/jenkins/jobs/BUILD_BACK/builds/1801/archive/vulnerabilities/vulnerabilities.json
/var/lib/jenkins/jobs/BUILD_BACK/builds/1801/archive/vulnerabilities/vulnerabilities.spdx.json
/var/lib/jenkins/jobs/BUILD_BACK/builds/1801/archive/vulnerabilities/vulnerabilities_syft.spdx.json
/var/lib/jenkins/jobs/BUILD_BACK/builds/1801/archive/vulnerabilities/trivy_sbom_report.json
/var/lib/jenkins/jobs/BUILD_BACK/builds/1801/archive/vulnerabilities/trivy_sbom.json
/var/lib/jenkins/jobs/BUILD_BACK/builds/1801/archive/vulnerabilities/vulnerabilities_trivy.spdx.json
/var/lib/jenkins/jobs/BUILD_BACK/builds/1801/archive/vulnerabilities/vulnerabilities_syft.json
```

## Скачать конкретный файл
curl -O "https://jenkins.runtel.ru/view/v2/job/BUILD_BACK/1801/artifact/vulnerabilities/vulnerabilities_syft.json"

## Или все файлы скачать
wget -r --no-parent "https://jenkins.runtel.ru/view/v2/job/BUILD_BACK/1801/artifact/vulnerabilities/"

## На Master ноду Jenkins можно удалить лишнее
```bash
# Вариант 1: Brace expansion (рекомендуется)
sudo rm -rf {80..90}

# Вариант 2: Использовать seq
sudo rm -rf $(seq 80 90)

# Вариант 3: Цикл for
for i in {80..90}; do sudo rm -rf "$i"; done

### Вариант 4: Использовать find с числовым сравнением
sudo find . -maxdepth 1 -type d -name "[0-9]*" -exec bash -c '[[ $(basename {}) -ge 80 && $(basename {}) -le 90 ]]' \; -exec rm -rf {} +

#Или по одному, если хотите видеть прогресс:

for i in {80..90}; do
    echo "Удаляем $i"
    sudo rm -rf "$i"
done
```

