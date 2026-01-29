Оф. док.: https://www.jenkins.io/doc/book/using/using-credentials/
<br/> https://www.jenkins.io/doc/book/using/using-credentials/#adding-new-global-credentials

Dashboard -> Настроить Jenkins -> Security
<br/> Создать пользователя на странице https://jenkins.runtel.ru/manage/configureSecurity/
<br/> создал пользователя gitlab-bot

Dashboard -> Настроить Jenkins -> Credentials -> System -> Global credentials (unrestricted)
<br/> На странице https://jenkins.runtel.ru/manage/credentials/store/system/domain/_/newCredentials
<br/> задать пароль пользователю gitlab-bot
<br/> Опционально задать ID, например, 1010

Разлогиниться из-под admin, зайти под gitlab-bot.

Получить инфо по Jenkins-Crumb:
```bash
curl -s -u "admin:**********" "https://jenkins.runtel.ru/crumbIssuer/api/json" -H "Accept: application/json" | jq
```

Добавить в .gitlab-ci.yml
```yml
trigger_jenkins:
  script:
    - |
      CRUMB=$(curl -s -u "admin:ваш_токен" "https://jenkins.runtel.ru/crumbIssuer/api/json" | jq -r .crumb)
      curl -X POST \
        -H "Jenkins-Crumb: $CRUMB" \
        -H "Authorization: Basic $(echo -n 'admin:ваш_токен' | base64)" \
        "https://jenkins.runtel.ru/job/nested_stages_front_test/build"
```

Тест с новым crumb:
```bash
CRUMB=$(curl -s -u "admin:<your_pass>" "https://jenkins.runtel.ru/crumbIssuer/api/json" | jq -r .crumb)
echo "Токен: $CRUMB"

curl -v -X POST \
  -u "admin:ohriep7eixoV" \
  -H "Jenkins-Crumb: $CRUMB" \
  -H "Referer: https://jenkins.runtel.ru" \
  "https://jenkins.runtel.ru/job/nested_stages_front_test/build"
```
-------------------------------------

Например, зайти на https://gitlab.runtel.org/runtel/rt-v2, выбрать Settings -> integrations -> jenkins или сразу https://gitlab.runtel.org/runtel/rt-v2/-/settings/integrations/jenkins/edit
  - Jenkins server URL: https://jenkins.runtel.ru/
  - Project name: rt_v2_deb10_dev
  - Username: admin
  - Enter new password: <можно вставить сгенерированный токен в Jenkins>

