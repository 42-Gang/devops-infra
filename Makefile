# ----------------------------------
# Global Config
# ----------------------------------
MSA_NAMESPACE := msa
TRAEFIK_NAMESPACE := traefik

REGISTRY := kungbi
USER_SERVER_IMAGE_NAME := user-server
AUTH_SERVER_IMAGE_NAME := auth-server
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
	kubectl create namespace $(MSA_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace $(TRAEFIK_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

delete-namespace:
	kubectl delete namespace $(MSA_NAMESPACE)
	kubectl delete namespace $(TRAEFIK_NAMESPACE)

# ----------------------------------
# MariaDB
# ----------------------------------

install-mariadb:
	helm install mariadb-user $(CHART_REPO)/mariadb \
		-n $(MSA_NAMESPACE) \
		-f helm/mariadb-user/values.yaml

	helm install mariadb-auth $(CHART_REPO)/mariadb \
		-n $(MSA_NAMESPACE) \
		-f helm/mariadb-auth/values.yaml

uninstall-mariadb:
	helm uninstall mariadb-user -n $(NAMESPACE)
	helm uninstall mariadb-auth -n $(NAMESPACE)

# ----------------------------------
# Redis
# ----------------------------------

install-redis:
	helm install redis-user $(CHART_REPO)/redis \
		-n $(MSA_NAMESPACE) \
		-f helm/redis-user/values.yaml

	helm install redis-auth $(CHART_REPO)/redis \
		-n $(MSA_NAMESPACE) \
		-f helm/redis-auth/values.yaml

uninstall-redis:
	helm uninstall redis-user -n $(MSA_NAMESPACE)
	helm uninstall redis-auth -n $(MSA_NAMESPACE)

# ----------------------------------
# Kafka (KRaft 모드)
# ----------------------------------

install-kafka:
	helm install kafka $(CHART_REPO)/kafka \
		-n $(MSA_NAMESPACE) \
		-f helm/kafka/values.yaml

upgrade-kafka:
	helm upgrade kafka $(CHART_REPO)/kafka \
		-n $(MSA_NAMESPACE) \
		-f helm/kafka/values.yaml

uninstall-kafka:
	helm uninstall kafka -n $(MSA_NAMESPACE)

# ----------------------------------
# Deploy User Server (Helm Chart 사용 가정)
# ----------------------------------

deploy-user:
	helm upgrade --install user-server ./helm/user-server \
		-n $(MSA_NAMESPACE) \
		--set image.repository=$(REGISTRY)/$(IMAGE_NAME) \
		--set image.tag=$(IMAGE_TAG)

uninstall-user:
	helm uninstall user-server -n $(MSA_NAMESPACE)

rollback-user:
	helm rollback user-server -n $(MSA_NAMESPACE)

deploy-auth:
	helm upgrade --install auth-server ./helm/auth-server \
		-n $(MSA_NAMESPACE) \
		--set image.repository=$(REGISTRY)/auth-server \
		--set image.tag=$(IMAGE_TAG)

uninstall-auth:
	helm uninstall auth-server -n $(MSA_NAMESPACE)

rollback-auth:
	helm rollback auth-server -n $(MSA_NAMESPACE)


# ----------------------------------
# Traefik
# ----------------------------------

deploy-traefik:
	helm install traefik traefik/traefik \
		-n $(TRAEFIK_NAMESPACE) \
		--values helm/traefik/values.yaml \
		-f helm/traefik/values.yaml \
		--skip-crds=false

# ----------------------------------
# Secrets
# ----------------------------------

apply-secrets:
	kubectl apply -f ./secrets/server-secret.yaml -n $(MSA_NAMESPACE)
	kubectl apply -f ./secrets/mariadb-secret.yaml -n $(MSA_NAMESPACE)


# ----------------------------------
# All-in-One
# ----------------------------------

install: add-helm-repo create-namespace apply-secrets install-mariadb install-redis install-kafka

deploy-all: deploy-user deploy-auth

reset:
	helm uninstall mariadb-user -n $(MSA_NAMESPACE) || true
	helm uninstall mariadb-auth -n $(MSA_NAMESPACE) || true

	helm uninstall redis-user -n $(MSA_NAMESPACE) || true
	helm uninstall redis-auth -n $(MSA_NAMESPACE) || true

	helm uninstall kafka -n $(MSA_NAMESPACE) || true

	helm uninstall user-server -n $(MSA_NAMESPACE) || true
	helm uninstall auth-server -n $(MSA_NAMESPACE) || true

	kubectl delete all,cm,secret,pvc -n $(MSA_NAMESPACE) || true