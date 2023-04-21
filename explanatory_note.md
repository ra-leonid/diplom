# Создание облачной инфраструктуры
Используемые версии:
terraform v1.4.2
terraform yandex provider v0.88.0
kubespray v2.21.0

Разработка и отладка велась локально, с прицелом на использование Atlantis, но в последствии запуск поменял на terraform-cloud.

## Обновляем terraform до последней версии

<details>
    <summary>Перед началом обновления terraform поднимаем free vpn.</summary>
    <p>

1. Устанавливаем OpenVpn:
```commandline
sudo apt-get install openvpn
```
2. Создаём каталог и переходим в него:
```commandline
mkdir ~/vpnbook
```
3. С [сайта](https://www.vpnbook.com/) качаем один из файлов настройки vpn в созданный каталог:

![](./img/vpnbook.png)
4. Настройка:
```commandline
cd ~/vpnbook

# Распаковать файлы настроек OpenVPN 
jar xvf vpnbook-openvpn-pl226.zip
rm vpnbook-openvpn-pl226.zip

# Создать файл с данными авторизации (их берём с сайта vpnbook см. скрин)
cat > auth.txt <<EOF
vpnbook
dd4e58m
EOF

# Заменить строку «auth-user-pass» на «auth-user-pass auth.txt»
sed -i 's/auth-user-pass/auth-user-pass auth.txt/' vpnbook-pl226-udp53.ovpn
```
5. Поднимаем VPN:
```commandline
sudo openvpn --config ~/vpnbook/vpnbook-pl226-udp53.ovpn
```
    </p>
</details>

Обновление terraform выполнялось по инструкции с [сайта](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform)

```commandline
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```
### Результат:
![](img/update-terraform.png)

## Предварительная подготовка к установке и запуску Kubernetes кластера.
1. Создаём каталог с авторизационными данными (добавлен в .gitignore):
```commandline
mkdir ./.secrets

```
2. Создаём сервисный аккаунт:
```commandline
# Узнать список каталогов
yc resource-manager folder list

# Создать сервисный аккаунт для выбранного каталога
yc iam service-account create --name sa-terraform --folder-name new --description "this is a service account for working with terraform"

# Назначить роль editor
yc resource-manager folder add-access-binding new --role editor --subject serviceAccount:aje32701sqo6nkcbvdsp

# Создать файл авторизации
yc iam key create --folder-name new --service-account-name sa-terraform --output secrets/.key.json
```
2. Создаём статический ключ доступа:
```commandline
yc iam access-key create --folder-name new --service-account-name sa-terraform
```
3. Сохраняем данные статического ключа для дальнейшего использования при доступе к s3 bucket:
```commandline
cat > ./.secrets/backend.conf <<EOF
access_key="xxx"
secret_key="xxx"
EOF
terraform init -reconfigure -backend-config=./.secrets/backend.conf
```

<details>
    <summary>Другие варианты использования статического ключа</summary>
    <p>

1. В credetials AWS:
```commandline
mkdir ~/.aws
cat > ~/.aws/auth.txt <<EOF
[default]
aws_access_key_id="xxx"
aws_secret_access_key="xxx"
EOF
```
2. В секции backend файла backend.tf (плохой вариант):
```terraform
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "tfstate-diplom-devops"
    region     = "ru-central1"
    key        = "terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    access_key = "xxx"
    secret_key = "xxx"
  }
}
```
2. В переменных среды:
```commandline
export AWS_ACCESS_KEY_ID="xxx"
export AWS_SECRET_ACCESS_KEY="xxx"
```
3. Передавать в параметрах выполнения команд terraform:
```commandline
terraform init -reconfigure \
    -backend-config="access_key=xxx" \
    -backend-config="secret_key=xxx"
```
    </p>
</details>

4. Создаём S3 бакет:
```commandline
yc storage bucket create --name tfstate-diplom-devops
```

## Настройка workspace
1. Создаём рабочие пространства:
```commandline
terraform workspace new stage
terraform workspace new prod
```
2. Список пространств:
```commandline
terraform workspace list
```
3. Выбираем нужное пространство:
```commandline
terraform workspace select stage
```
4. Тестируем
```commandline
terraform apply -auto-approve
terraform destroy -auto-approve
```

# Создание Kubernetes кластера.
Кластер разворачиваем с помощью Kuberspray. 
* Для `stage` окружения поднимаем: 1 control-plane и 1 node;
* Для `prod` окружения поднимаем: 3 control-plane и 3 node, в разных зонах доступности;

Доступ к k8s-инстансам будет только через nat-instance, все ВМ кластера без публичных ip.

Конфигурация Kuberspray и запуск выполняются автоматически посредством terraform, сразу после поднятия инфраструктуры.

Создаем каталог и загружаем `kubespray` <https://github.com/kubernetes-sigs/kubespray>.
```commandline
git submodule add https://github.com/kubernetes-sigs/kubespray src/vendor/kubespray
```
* Настройка хостов в ресурсе `kuberspray_inventory` файла [inventory.tf](src/terraform/app/inventory.tf);
* Старт установки реализован в файле [kubespray.tf](src/terraform/app/kubespray.tf);

Реализуем "проброс" подключения к ВМ приватной сети через nat-instance:
1. В [host.tpl](src/terraform/app/templates/hosts.tpl) добавляем секцию "bastion".
2. В [site.yml](src/ansible/site.yml) реализуем проброс "~/.kube/config", заполнение "server" и "proxy-url", ssh-туннель.

### Результат:
![](img/create-k8s-cluster.png)

---
```commandline
# Первая инициализация:
terraform init -reconfigure -backend-config=./.secrets/backend.conf
terraform workspace select stage
terraform init
terraform validate
terraform plan

terraform apply -auto-approve
terraform destroy -auto-approve

ssh -D 1337 -f -C -q -N ubuntu@62.84.126.49 -p 22322
sudo systemctl restart ssh
```

# Создание тестового приложения
* Создаем образ командой ```docker image build -t raleonid/app-meow:0.0.1 .```
* Запускаем контейнер командой ```docker run -d -p 8080:80 raleonid/app-meow:0.0.1```
* Проверяем

```commandline
# Авторизуемся
docker login
# Отправляем в докер-репозиторий
docker image push raleonid/app-meow:0.0.1
```
### Результат:
[Контейнер](https://hub.docker.com/repository/docker/raleonid/app-meow)

[Репозиторий тестового приложения](https://github.com/ra-leonid/app-meow)

## Подготовка cистемы мониторинга и деплой приложения

Деплой основного приложения будем осуществлять посредством helm.
Для того, чтобы выполнять автодеплой при коммитах и созданиях тегов, чарт проекта расположим в репозитории основного проекта.
Дл общего деплоя, проект будем загружать в папку `.src/deploy/app` и оттуда деплоить.

### Настройка деплоя приложения:
Деплой приложения осуществляем посредством helm.
1. Создаём каталог и инициализируем приложение:
```commandline
helm create app
```
2. Описываем создание приложения в файлах каталога, лишние очищаем, удаляем.
3. Команда деплоя:
```commandline
helm upgrade --install app-meow app --create-namespace -n stage
```

### Настройка деплоя kube-prometheus
Деплой kube-prometheus выполняем с помощью helm.
1. Создаём каталог, получаем настройки чарта:
```commandline
mkdir -p src/deploy/kube-prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm show values prometheus-community/kube-prometheus-stack > src/deploy/kube-prometheus/values.yaml
```
2. В настройках чарта меняем (**только указанные значения!**) в секции `grafana.service`:
```yaml
//...
grafana:
//...
  service:
    type: NodePort
    nodePort: 30001
//...
```

Итоговый файл настроек [values.yaml](src/deploy/kube-prometheus/values.yaml).
3. Команда деплоя:
```commandline
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack --create-namespace -n debug -f src/deploy/kube-prometheus/values.yaml --set grafana.ingress.hosts[0]=grafana.meow-app.local
```

Для получения пароля, выполняем команду:
```commandline
kubectl get secret monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

**TODO**: Реализовать безопасное хранение пароля админа, реализовать установку с помощью qbec.

### Настройка деплоя atlantis
<details>
    <summary>В итоговый вариант не вошел.</summary>
Деплой atlantis выполняем с помощью helm.
1. Создаём каталог, получаем настройки чарта:
```commandline
mkdir -p src/deploy/atlantis
helm repo add runatlantis https://runatlantis.github.io/helm-charts
helm show values runatlantis/atlantis > src/deploy/atlantis/values.yaml
```
2. По [инструкции](https://www.runatlantis.io/docs/installation-guide.html) выполняем настройку
   1. Заходим `http://84.201.129.2:4000/github-app/setup`
3. В настройках чарта меняем (**только указанные значения!**) в секциях:
```yaml
//...
orgAllowlist: github.com/runatlantis/*
//...
github:
   user: "ra-leonid"
   token: "xxx"
   secret: "yyy"
//...
ingress:
//...
  hosts:
    - host: atlantis.meow-app.ru
      paths: ["/"]
 //...
```

Итоговый файл настроек [values.yaml](src/deploy/atlantis/values.yaml).
3. Команда деплоя:
```commandline
helm upgrade --install atlantis runatlantis/atlantis --create-namespace -n prod -f src/deploy/atlantis/values.yaml --set ingress.hosts[0].host=atlantis.meow-app.local
```

**TODO**: Реализовать безопасное хранение token и secret, разобраться как задается пароль админа, реализовать установку с помощью qbec.
</details>

## Установка и настройка CI/CD
1. Создаём каталог, получаем настройки чарта:
```commandline
mkdir -p src/deploy/jenkins
helm repo add jenkins https://charts.jenkins.io
helm show values jenkins/jenkins > src/deploy/jenkins/values-base.yaml
```
2. В настройках чарта меняем (**только указанные значения!**) в секциях:
```yaml
//...
controller:
//...
  jenkinsUrl: "http://158.160.100.209:9000/"
//...
  serviceType: NodePort
  nodePort: 30002
//...
  installPlugins:
    - github-branch-source:1703.vd5a_2b_29c6cdc
    - kubernetes:3910.ve59cec5e33ea_
    - kubernetes:3923.v294a_d4250b_91
    - docker-workflow:563.vd5d2e5c4007f
    - kubernetes-cli:1.12.0
//...
persistence:
  storageClass: nfs
//...
serviceAccount:
  create: false 
  name: jenkins

```

Итоговый файл настроек [values.yaml](src/deploy/jenkins/values.yaml).
3. Чтобы jenkins мог сохранять своё состояние, необходимо установить `nfs-provigioner`. Для этого, в makefile создаем 
отдельный подготовительный этап перед деплоем всех приложений, в который также выносим подключение всех необходимых 
репозиториев чартов:
```makefile
configure_deploy:
	helm repo add jenkins https://charts.jenkins.io
	helm repo add nfs-ganesha-server-and-external-provisioner https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner/
	helm repo update
	helm upgrade --install nfs-server nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner
```
Создаём playbook по установке на нодах пакетов, необходимых для работы `nfs-provigioner`. Создаём отдельную папку:
[nfs.yml](src/playbook/nfs.yml).
4. Команды деплоя:
```commandline
#helm upgrade --install jenkins jenkins/jenkins --create-namespace -n debug -f src/deploy/jenkins/values.yaml --set controller.ingress.hostName=jenkins.meow-app.local
kubectl -n $(ns) apply -f ./src/deploy/jenkins/sa.yaml
helm upgrade --install jenkins -n $(ns) -f ./src/deploy/jenkins/values.yaml jenkins/jenkins
```
5. Для получения пароля, выполняем команду:
```commandline
kubectl -n prod get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode ; echo
```

6. Внутренняя настройка Jenkins:
   1. Создаем credentials для подключения к репозиториям github:

   ![](img/github-auth.png)

   2. Создаем credentials для подключения к dockerhub:
   
   ![](img/dockerhub-auth.png)

   3. Создаем credentials с токеном сервисного аккаунта `jenkins` в k8s:
```commandline
# Команда получения токена
kubectl -n prod get secret jenkins-prod-token -o go-template --template '{{index .data "token"}}' | base64 -d ; echo
```
   ![](img/token-k8s-sa.png)

   4. Настраиваем `GitHub API usage`, чтобы пайплайн нам мозг не делал с задержками обращения к GitHub на этапе отладки. Устанавливаем значение `Throttle at/near rate limit`: 

   ![](img/GitHub API usage.png)

   5. Настраиваем `GitHub Servers`, в credentials указываем тип `secret text` и заполняем персональным токеном УЗ GitHub:

   ![](img/token-github.png)

   ![](img/github-server.png)

   6. Создаём Multibranch Pipeline, настраиваем его работу с проектом в репозитории github
   7. В репозитории github создаём webhook на события `Branch or tag creation` и `Commit comments`.
    Payload URL `http://158.160.59.53:9000/github-webhook/`

   ![](img/jenkins-webhook.png)

   ![](img/jenkins-webhook-test.png)
   
   ![](img/shared-secret.png)

   8. Создаём пайплайн исходя из условий задачи.

      ![](img/pipeline-1.png)

      ![](img/pipeline-strategy.png)

      1. _При любом коммите в репозиторий с тестовым приложением, происходит сборка и отправка в регистр Docker образа._
         Т.к. веток может быть много, чтобы при коммитах из разных веток, образ не перезаписывался, нам и в этой задаче нужно отправлять с тегами.
         Условимся, что в данном случае, имя тега будет состоять из имени ветки и билда сборки. Например `main-46`.
      2. В тестовом приложении, создаем [Jenkinsfile](https://github.com/ra-leonid/app-meow/blob/main/Jenkinsfile).
      3. Для автодеплоя переносим манифесты приложения в его репозиторий. (TODO: В дальнейшем в большом изначальном деплое подтягивать приложение как подпроект гита)
      4. Для сбора докер-образа, используем образ `docker:18.05-dind` stage('Build') (TODO: разобраться почему не получилось запустить сборку kaniko):
      5. Для деплоя используем helm и kubectl

   9. Проверяем что всё работает:

   ![](img/pipeline-autostart-pods.png)
   
   ![](img/pipeline-branch.png)

   ![](img/pipeline-tag.png)


Генерируем личный токен разработчика

Настраиваем в проекте github webhook: `http://158.160.102.29:9000/github-webhook/`

Тестируем работу webhook:
```commandline
git add . && git commit --amend --no-edit && git push
git add . && git commit -m "Add teg v0.0.1" && git push

git tag -a v0.0.1 -m "Test webhook tag"
git push origin v0.0.1
```

```commandline
# Создаем образ командой:
docker image build -t raleonid/inbound-agent:3107.v665000b_51092-5 .

# Авторизуемся
docker login
# Отправляем в докер-репозиторий
docker image push raleonid/inbound-agent:3107.v665000b_51092-5
```
      3. В настройках Jenkins, пропишем его использование.
```yaml
//...
agent:
//...
  image: "raleonid/inbound-agent"
```


Для автоматического деплоя, нам необходимо получить токен сервисного аккаунта jenkins.
[В Kubernetes 1.24 секреты ServiceAccount больше не генерируются автоматически.](https://stackoverflow.com/questions/72256006/service-account-secret-is-not-listed-how-to-fix-it)
Вам нужно вручную создать секрет, ключ token в data поле будет автоматически установлен.
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-token
  annotations:
    kubernetes.io/service-account.name: jenkins
type: kubernetes.io/service-account-token
```
Поскольку вы создаете секрет вручную, вы знаете его name, и вам не нужно искать его в объекте ServiceAccount.
Этот подход должен хорошо работать и в более ранних версиях Kubernetes.

Получаем токен сервисного аккаунта:
```commandline
kubectl -n prod get secrets jenkins-token -o go-template --template '{{index .data "token"}}' | base64 -d ; echo
```

Сохраняем его в credentials Jenkins id=`jenkins-token`:
TODO: вставить скрин

Для деплоя внутри пайплайна, используем конструкцию (требуется установка плагина `kubernetes-cli`). 
```commandline
        withKubeConfig([credentialsId: 'jenkins-token']) {
            sh 'curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.26.1/bin/linux/amd64/kubectl"'
            sh 'chmod u+x ./kubectl'
            sh './kubectl get pods -n stage'
        }

```
