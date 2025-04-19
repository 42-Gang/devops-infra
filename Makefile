# ----------------------------------
# Global Config
# ----------------------------------
NAMESPACE := msa
REGISTRY := kungbi
IMAGE_NAME := user-server
IMAGE_TAG := latest
FULL_IMAGE := $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
CHART_REPO := bitnami
CHART_URL := https://charts.bitnami.com/bitnami

# ----------------------------------
# Helm Repos
# ----------------------------------

add-helm-repo:
	helm repo add $(CHART_REPO) $(CHART_URL)
	helm repo update

# ----------------------------------
# Namespace
# ----------------------------------

create-namespace:
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

delete-namespace:
	kubectl delete namespace $(NAMESPACE)

# ----------------------------------
# MariaDB
# ----------------------------------

install-mariadb:
	helm install mariadb-user $(CHART_REPO)/mariadb \
		-n $(NAMESPACE) \
		-f helm/mariadb-user/values.yaml

	helm install mariadb-auth $(CHART_REPO)/mariadb \
    		-n $(NAMESPACE) \
    		-f helm/mariadb-auth/values.yaml

uninstall-mariadb:
	helm uninstall mariadb-user -n $(NAMESPACE)
	helm uninstall mariadb-auth -n $(NAMESPACE)

# ----------------------------------
# Redis
# ----------------------------------

install-redis:
	helm install redis-user $(CHART_REPO)/redis \
		-n $(NAMESPACE) \
		-f helm/redis-user/values.yaml

	helm install redis-auth $(CHART_REPO)/redis \
    		-n $(NAMESPACE) \
    		-f helm/redis-auth/values.yaml

uninstall-redis:
	helm uninstall redis-user -n $(NAMESPACE)
	helm uninstall redis-auth -n $(NAMESPACE)

# ----------------------------------
# Kafka (KRaft 모드)
# ----------------------------------

install-kafka:
	helm install kafka $(CHART_REPO)/kafka \
		-n $(NAMESPACE) \
		-f helm/kafka/values.yaml

upgrade-kafka:
	helm upgrade kafka $(CHART_REPO)/kafka \
		-n $(NAMESPACE) \
		-f helm/kafka/values.yaml

uninstall-kafka:
	helm uninstall kafka -n $(NAMESPACE)

# ----------------------------------
# Deploy User Server (Helm Chart 사용 가정)
# ----------------------------------

deploy-user:
	helm upgrade --install user-server ./helm/user-server \
		-n $(NAMESPACE) \
		--set image.repository=$(REGISTRY)/$(IMAGE_NAME) \
		--set image.tag=$(IMAGE_TAG)

uninstall-user:
	helm uninstall user-server -n $(NAMESPACE)

rollback-user:
	helm rollback user-server -n $(NAMESPACE)

deploy-auth:
	helm upgrade --install auth-server ./helm/auth-server \
		-n $(NAMESPACE) \
		--set image.repository=$(REGISTRY)/auth-server \
		--set image.tag=$(IMAGE_TAG)

uninstall-auth:
	helm uninstall auth-server -n $(NAMESPACE)

rollback-auth:
	helm rollback auth-server -n $(NAMESPACE)

# ----------------------------------
# Secrets
# ----------------------------------

apply-secrets:
	kubectl apply -f ./secrets/user-mariadb-secret.yaml -n $(NAMESPACE)
	kubectl apply -f ./secrets/user-server-secret.yaml -n $(NAMESPACE)
	kubectl apply -f ./secrets/auth-server-secret.yaml -n $(NAMESPACE)
	kubectl apply -f ./secrets/auth-mariadb-secret.yaml -n $(NAMESPACE)


# ----------------------------------
# All-in-One
# ----------------------------------

install: add-helm-repo create-namespace apply-secrets install-mariadb install-redis install-kafka

deploy-all: deploy-user deploy-auth

reset:
	helm uninstall mariadb-user -n $(NAMESPACE) || true
	helm uninstall mariadb-auth -n $(NAMESPACE) || true

	helm uninstall redis-user -n $(NAMESPACE) || true
	helm uninstall redis-auth -n $(NAMESPACE) || true

	helm uninstall kafka -n $(NAMESPACE) || true

	helm uninstall user-server -n $(NAMESPACE) || true
	helm uninstall auth-server -n $(NAMESPACE) || true

	kubectl delete all,cm,secret,pvc -n $(NAMESPACE) || true