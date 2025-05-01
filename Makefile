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
	helm repo add traefik https://traefik.github.io/charts
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

install-mariadb: apply-secrets
	helm upgrade mariadb-user $(CHART_REPO)/mariadb \
		--install \
		-n $(MSA_NAMESPACE) \
		-f helm/mariadb-user/values.yaml

	helm upgrade mariadb-auth $(CHART_REPO)/mariadb \
		--install \
		-n $(MSA_NAMESPACE) \
		-f helm/mariadb-auth/values.yaml

	helm upgrade mariadb-chat $(CHART_REPO)/mariadb \
		--install \
		-n $(MSA_NAMESPACE) \
		-f helm/mariadb-chat/values.yaml

uninstall-mariadb:
	helm uninstall mariadb-user -n $(MSA_NAMESPACE)
	helm uninstall mariadb-auth -n $(MSA_NAMESPACE)
	#helm uninstall mariadb-chat -n $(MSA_NAMESPACE)

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

	helm install redis-chat $(CHART_REPO)/redis \
    		-n $(MSA_NAMESPACE) \
    		-f helm/redis-chat/values.yaml

uninstall-redis:
	helm uninstall redis-user -n $(MSA_NAMESPACE)
	helm uninstall redis-auth -n $(MSA_NAMESPACE)
	helm uninstall redis-chat -n $(MSA_NAMESPACE)

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

deploy-user: apply-secrets
	helm upgrade --install user-server ./helm/user-server \
		-n $(MSA_NAMESPACE)

uninstall-user:
	helm uninstall user-server -n $(MSA_NAMESPACE)

rollback-user:
	helm rollback user-server -n $(MSA_NAMESPACE)

restart-user:
	kubectl rollout restart deployment user-server -n $(MSA_NAMESPACE)

# ----------------------------------

deploy-auth: apply-secrets
	helm upgrade --install auth-server ./helm/auth-server \
		-n $(MSA_NAMESPACE)

uninstall-auth:
	helm uninstall auth-server -n $(MSA_NAMESPACE)

rollback-auth:
	helm rollback auth-server -n $(MSA_NAMESPACE)

restart-auth:
	kubectl rollout restart deployment auth-server -n $(MSA_NAMESPACE)

# ----------------------------------

deploy-chat: apply-secrets
	helm upgrade --install chat-server ./helm/chat-server \
		-n $(MSA_NAMESPACE)

uninstall-chat:
	helm uninstall chat-server -n $(MSA_NAMESPACE)

rollback-chat:
	helm rollback chat-server -n $(MSA_NAMESPACE)

restart-chat:
	kubectl rollout restart deployment chat-server -n $(MSA_NAMESPACE)

# ----------------------------------
# Traefik
# ----------------------------------

deploy-traefik:
	helm upgrade traefik traefik/traefik \
		--install \
		-n $(TRAEFIK_NAMESPACE) \
		--values helm/traefik/values.yaml \
		-f helm/traefik/values.yaml \
		--skip-crds=false
	kubectl apply -f ./traefik/auth-middleware.yaml
	kubectl apply -f ./traefik/ws-middleware.yaml
	kubectl apply -f ./traefik/cors-middleware.yaml
	kubectl apply -f ./traefik/ingressroute.yaml

delete-traefik:
	helm uninstall traefik -n $(TRAEFIK_NAMESPACE)

# ----------------------------------
# Secrets
# ----------------------------------

apply-secrets:
	kubectl apply -f ./secrets/server-secret.yaml -n $(MSA_NAMESPACE)
	kubectl apply -f ./secrets/mariadb-secret.yaml -n $(MSA_NAMESPACE)


apply-local-path:
	kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml

# ----------------------------------
# All-in-One
# ----------------------------------

install: apply-local-path create-namespace apply-secrets install-mariadb install-redis install-kafka

deploy-all: deploy-user deploy-auth deploy-chat

reset:
	helm uninstall mariadb-user -n $(MSA_NAMESPACE) || true
	helm uninstall mariadb-auth -n $(MSA_NAMESPACE) || true
	helm uninstall mariadb-chat -n $(MSA_NAMESPACE) || true

	helm uninstall redis-user -n $(MSA_NAMESPACE) || true
	helm uninstall redis-auth -n $(MSA_NAMESPACE) || true
	helm uninstall redis-chat -n $(MSA_NAMESPACE) || true

	helm uninstall kafka -n $(MSA_NAMESPACE) || true

	helm uninstall user-server -n $(MSA_NAMESPACE) || true
	helm uninstall auth-server -n $(MSA_NAMESPACE) || true
	helm uninstall chat-server -n $(MSA_NAMESPACE) || true

	kubectl delete all,cm,secret,pvc -n $(MSA_NAMESPACE) || true
	kubectl delete all,cm,secret,pvc || true