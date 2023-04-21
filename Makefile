
ns ?= stage
appStartTag ?= "v0.0.5"

SLEEP_COUNT := 120

all: init apply pause setting_nfs deploy_k8s pause configuring_access_to_k8s tunnel

destroy:
	terraform destroy -auto-approve

init:
	terraform init -reconfigure -backend-config=./.secrets/backend.conf
	# terraform init
	# terraform workspace new $(ns)

apply:
	terraform workspace select $(ns)
	terraform apply -auto-approve

deploy_k8s:
	cd ./src/vendor/kubespray && ANSIBLE_FORCE_COLOR=1 ansible-playbook -i ./inventory/mycluster/hosts.yaml --become --become-user=root cluster.yml

pause:
	echo "Wait for $(SLEEP_COUNT) seconds stupid k8s creating..."
	sleep $(SLEEP_COUNT)
	echo "May be created? Ok, run an deploy..."

tunnel:
	cd ./src/playbook && ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory.yml ssh_tunnel.yml

setting_nfs:
	cd ./src/playbook && ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory.yml nfs.yml

deploy: configure_deploy deploy_monitoring deploy_app deploy_atlantis deploy_jenkins

configure_deploy:
	helm repo add jenkins https://charts.jenkins.io
	helm repo add nfs-ganesha-server-and-external-provisioner https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner/
	helm repo update
	helm upgrade --install nfs-server nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner

deploy_app:
	rm -Rf ./src/deploy/app
	git clone https://github.com/ra-diplom1/app-meow.git ./src/deploy/app
	helm upgrade --install app-meow ./src/deploy/app/deploy --create-namespace -n $(ns) --set image.tag=$(appStartTag)

deploy_monitoring:
	helm upgrade --install monitoring prometheus-community/kube-prometheus-stack --create-namespace -n $(ns) -f src/deploy/kube-prometheus/values.yaml

deploy_atlantis:
	helm upgrade --install atlantis runatlantis/atlantis --create-namespace -n $(ns) -f src/deploy/atlantis/values.yaml

deploy_jenkins:
	helm upgrade --install jenkins-sa ./src/deploy/jenkins/jenkins-sa -n stage
	helm upgrade --install jenkins -n $(ns) -f ./src/deploy/jenkins/values.yaml jenkins/jenkins

delete:
	helm uninstall monitoring -n $(ns)
	helm uninstall atlantis -n $(ns)
	helm uninstall jenkins -n $(ns)
	helm uninstall app-meow -n $(ns)

configuring_access_to_k8s:
	cd ./src/playbook && ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory.yml configuring_access_to_k8s.yml
