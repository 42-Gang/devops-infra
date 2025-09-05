# ----------------------------------
# Global Config
# ----------------------------------
MSA_NAMESPACE        := msa
TRAEFIK_NAMESPACE    := traefik
MONITOR_NAMESPACE    := monitor

REGISTRY             := kungbi
USER_SERVER_IMAGE    := user-server
AUTH_SERVER_IMAGE    := auth-server
CHAT_SERVER_IMAGE    := chat-server
IMAGE_TAG            := latest
FULL_IMAGE           := $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

CHART_REPO           := bitnami
CHART_URL            := https://charts.bitnami.com/bitnami

# ----------------------------------
# Color Config
# ----------------------------------
COLOR_BLUE   := \033[1;34m
COLOR_GREEN  := \033[1;32m
COLOR_YELLOW := \033[1;33m
COLOR_RESET  := \033[0m

# ----------------------------------
# Phony Targets
# ----------------------------------
.PHONY: \
  add-helm-repo \
  create-namespace delete-namespace \
  install-mariadb-user install-mariadb-auth install-mariadb-chat install-mariadb \
  uninstall-mariadb-user uninstall-mariadb-auth uninstall-mariadb-chat uninstall-mariadb \
  install-redis-user install-redis-auth install-redis-chat install-redis \
  uninstall-redis-user uninstall-redis-auth uninstall-redis-chat uninstall-redis \
  install-kafka upgrade-kafka uninstall-kafka \
  deploy-user uninstall-user rollback-user restart-user \
  deploy-auth uninstall-auth rollback-auth restart-auth \
  deploy-chat uninstall-chat rollback-chat restart-chat \
  deploy-traefik delete-traefik \
  apply-secrets apply-local-path \
  install deploy-all reset all

# ----------------------------------
# Helm Repos
# ----------------------------------
add-helm-repo:
	@printf "$(COLOR_BLUE)==> Adding Helm repositories$(COLOR_RESET)\n"
	helm repo add $(CHART_REPO) $(CHART_URL)
	helm repo add traefik https://traefik.github.io/charts

	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
	helm repo add elastic https://helm.elastic.co
	helm repo update

# ----------------------------------
# Namespace
# ----------------------------------
create-namespace:
	@printf "$(COLOR_BLUE)==> Creating namespaces$(COLOR_RESET)\n"
	kubectl create namespace $(MSA_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace $(MONITOR_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace $(TRAEFIK_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

delete-namespace:
	@printf "$(COLOR_YELLOW)==> Deleting namespaces$(COLOR_RESET)\n"
	kubectl delete namespace $(MSA_NAMESPACE)
	kubectl delete namespace $(MONITOR_NAMESPACE)
	kubectl delete namespace $(TRAEFIK_NAMESPACE)

# ----------------------------------
# Secrets & StorageClass
# ----------------------------------
apply-secrets:
	@printf "$(COLOR_BLUE)==> Applying secrets$(COLOR_RESET)\n"
	kubectl apply -f ./secrets/server-secret.yaml -n $(MSA_NAMESPACE)
	kubectl apply -f ./secrets/mariadb-secret.yaml -n $(MSA_NAMESPACE)

apply-local-path:
	@printf "$(COLOR_BLUE)==> Installing local-path provisioner$(COLOR_RESET)\n"
	kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml

# ----------------------------------
# MariaDB (개별/통합)
# ----------------------------------
install-mariadb-user: apply-secrets
	@printf "$(COLOR_GREEN)==> Installing MariaDB User$(COLOR_RESET)\n"
	helm upgrade mariadb-user $(CHART_REPO)/mariadb \
		--install \
		-n $(MSA_NAMESPACE) \
		-f helm/mariadb/mariadb-user/values.yaml

install-mariadb-auth: apply-secrets
	@printf "$(COLOR_GREEN)==> Installing MariaDB Auth$(COLOR_RESET)\n"
	helm upgrade mariadb-auth $(CHART_REPO)/mariadb \
		--install \
		-n $(MSA_NAMESPACE) \
		-f helm/mariadb/mariadb-auth/values.yaml

install-mariadb-chat: apply-secrets
	@printf "$(COLOR_GREEN)==> Installing MariaDB Chat$(COLOR_RESET)\n"
	helm upgrade mariadb-chat $(CHART_REPO)/mariadb \
		--install \
		-n $(MSA_NAMESPACE) \
		-f helm/mariadb/mariadb-chat/values.yaml

install-mariadb-main-game: apply-secrets
	@printf "$(COLOR_GREEN)==> Installing MariaDB Main Game$(COLOR_RESET)\n"
	helm upgrade mariadb-main-game $(CHART_REPO)/mariadb \
		--install \
		-n $(MSA_NAMESPACE) \
		-f helm/mariadb/mariadb-main-game/values.yaml


uninstall-mariadb-user:
	@printf "$(COLOR_YELLOW)==> Uninstalling MariaDB User$(COLOR_RESET)\n"
	helm uninstall mariadb-user -n $(MSA_NAMESPACE)

uninstall-mariadb-auth:
	@printf "$(COLOR_YELLOW)==> Uninstalling MariaDB Auth$(COLOR_RESET)\n"
	helm uninstall mariadb-auth -n $(MSA_NAMESPACE)

uninstall-mariadb-chat:
	@printf "$(COLOR_YELLOW)==> Uninstalling MariaDB Chat$(COLOR_RESET)\n"
	helm uninstall mariadb-chat -n $(MSA_NAMESPACE)

uninstall-mariadb-main-game:
	@printf "$(COLOR_YELLOW)==> Uninstalling MariaDB Main Game$(COLOR_RESET)\n"
	helm uninstall mariadb-main-game -n $(MSA_NAMESPACE)

uninstall-mariadb: \
	uninstall-mariadb-user \
	uninstall-mariadb-auth \
	uninstall-mariadb-chat \
	uninstall-mariadb-main-game

install-mariadb: \
	install-mariadb-user \
	install-mariadb-chat \
	install-mariadb-auth \
	install-mariadb-main-game

# ----------------------------------
# Redis (개별/통합)
# ----------------------------------
install-redis-user:
	@printf "$(COLOR_GREEN)==> Installing Redis User$(COLOR_RESET)\n"
	helm install redis-user $(CHART_REPO)/redis \
		-n $(MSA_NAMESPACE) \
		-f helm/redis/redis-user/values.yaml

install-redis-auth:
	@printf "$(COLOR_GREEN)==> Installing Redis Auth$(COLOR_RESET)\n"
	helm install redis-auth $(CHART_REPO)/redis \
		-n $(MSA_NAMESPACE) \
		-f helm/redis/redis-auth/values.yaml

install-redis-chat:
	@printf "$(COLOR_GREEN)==> Installing Redis Chat$(COLOR_RESET)\n"
	helm install redis-chat $(CHART_REPO)/redis \
		-n $(MSA_NAMESPACE) \
		-f helm/redis/redis-chat/values.yaml

install-redis-main-game:
	@printf "$(COLOR_GREEN)==> Installing Redis Main Game$(COLOR_RESET)\n"
	helm install redis-main-game $(CHART_REPO)/redis \
		-n $(MSA_NAMESPACE) \
		-f helm/redis/redis-main-game/values.yaml

install-redis: \
	install-redis-user \
	install-redis-auth \
	install-redis-chat \
	install-redis-main-game

uninstall-redis-user:
	@printf "$(COLOR_YELLOW)==> Uninstalling Redis User$(COLOR_RESET)\n"
	helm uninstall redis-user -n $(MSA_NAMESPACE)

uninstall-redis-auth:
	@printf "$(COLOR_YELLOW)==> Uninstalling Redis Auth$(COLOR_RESET)\n"
	helm uninstall redis-auth -n $(MSA_NAMESPACE)

uninstall-redis-chat:
	@printf "$(COLOR_YELLOW)==> Uninstalling Redis Chat$(COLOR_RESET)\n"
	helm uninstall redis-chat -n $(MSA_NAMESPACE)

uninstall-redis-main-game:
	@printf "$(COLOR_YELLOW)==> Uninstalling Redis Main Game$(COLOR_RESET)\n"
	helm uninstall redis-main-game -n $(MSA_NAMESPACE)

uninstall-redis: \
	uninstall-redis-user \
	uninstall-redis-auth \
	uninstall-redis-chat \
	uninstall-redis-main-game

# ----------------------------------
# Kafka (KRaft 모드)
# ----------------------------------
install-kafka:
	@printf "$(COLOR_GREEN)==> Installing Kafka (KRaft mode)$(COLOR_RESET)\n"
	helm install kafka $(CHART_REPO)/kafka \
		-n $(MSA_NAMESPACE) \
		-f helm/kafka/values.yaml

upgrade-kafka:
	@printf "$(COLOR_YELLOW)==> Upgrading Kafka$(COLOR_RESET)\n"
	helm upgrade kafka $(CHART_REPO)/kafka \
		-n $(MSA_NAMESPACE) \
		-f helm/kafka/values.yaml

uninstall-kafka:
	@printf "$(COLOR_YELLOW)==> Uninstalling Kafka$(COLOR_RESET)\n"
	helm uninstall kafka -n $(MSA_NAMESPACE)

# ----------------------------------
# Application Deployments
# ----------------------------------
deploy-user: apply-secrets
	@printf "$(COLOR_BLUE)==> Deploying User Server$(COLOR_RESET)\n"
	helm upgrade --install $(USER_SERVER_IMAGE) ./helm/services/user-server \
		-n $(MSA_NAMESPACE)

uninstall-user:
	@printf "$(COLOR_YELLOW)==> Uninstalling User Server$(COLOR_RESET)\n"
	helm uninstall $(USER_SERVER_IMAGE) -n $(MSA_NAMESPACE)

rollback-user:
	@printf "$(COLOR_YELLOW)==> Rolling back User Server$(COLOR_RESET)\n"
	helm rollback $(USER_SERVER_IMAGE) -n $(MSA_NAMESPACE)

restart-user:
	@printf "$(COLOR_BLUE)==> Restarting User Server$(COLOR_RESET)\n"
	kubectl rollout restart deployment $(USER_SERVER_IMAGE) -n $(MSA_NAMESPACE)

deploy-auth: apply-secrets
	@printf "$(COLOR_BLUE)==> Deploying Auth Server$(COLOR_RESET)\n"
	helm upgrade --install $(AUTH_SERVER_IMAGE) ./helm/services/auth-server \
		-n $(MSA_NAMESPACE)

uninstall-auth:
	@printf "$(COLOR_YELLOW)==> Uninstalling Auth Server$(COLOR_RESET)\n"
	helm uninstall $(AUTH_SERVER_IMAGE) -n $(MSA_NAMESPACE)

rollback-auth:
	@printf "$(COLOR_YELLOW)==> Rolling back Auth Server$(COLOR_RESET)\n"
	helm rollback $(AUTH_SERVER_IMAGE) -n $(MSA_NAMESPACE)

restart-auth:
	@printf "$(COLOR_BLUE)==> Restarting Auth Server$(COLOR_RESET)\n"
	kubectl rollout restart deployment $(AUTH_SERVER_IMAGE) -n $(MSA_NAMESPACE)

deploy-chat: apply-secrets
	@printf "$(COLOR_BLUE)==> Deploying Chat Server$(COLOR_RESET)\n"
	helm upgrade --install $(CHAT_SERVER_IMAGE) ./helm/services/chat-server \
		-n $(MSA_NAMESPACE)

uninstall-chat:
	@printf "$(COLOR_YELLOW)==> Uninstalling Chat Server$(COLOR_RESET)\n"
	helm uninstall chat-server -n $(MSA_NAMESPACE)

rollback-chat:
	@printf "$(COLOR_YELLOW)==> Rolling back Chat Server$(COLOR_RESET)\n"
	helm rollback chat-server -n $(MSA_NAMESPACE)

restart-chat:
	@printf "$(COLOR_BLUE)==> Restarting Chat Server$(COLOR_RESET)\n"
	kubectl rollout restart deployment chat-server -n $(MSA_NAMESPACE)

deploy-file: apply-secrets
	@printf "$(COLOR_BLUE)==> Deploying File Server$(COLOR_RESET)\n"
	helm upgrade --install file-server ./helm/services/file-server \
		-n $(MSA_NAMESPACE)

uninstall-file:
	@printf "$(COLOR_YELLOW)==> Uninstalling File Server$(COLOR_RESET)\n"
	helm uninstall file-server -n $(MSA_NAMESPACE)

rollback-file:
	@printf "$(COLOR_YELLOW)==> Rolling back File Server$(COLOR_RESET)\n"
	helm rollback file-server -n $(MSA_NAMESPACE)

restart-file:
	@printf "$(COLOR_BLUE)==> Restarting File Server$(COLOR_RESET)\n"
	kubectl rollout restart deployment file-server -n $(MSA_NAMESPACE)

deploy-main-game: apply-secrets
	@printf "$(COLOR_BLUE)==> Deploying File Server$(COLOR_RESET)\n"
	helm upgrade --install main-game-server ./helm/services/main-game-server \
		-n $(MSA_NAMESPACE)

uninstall-main-game:
	@printf "$(COLOR_YELLOW)==> Uninstalling File Server$(COLOR_RESET)\n"
	helm uninstall main-game-server -n $(MSA_NAMESPACE)

rollback-main-game:
	@printf "$(COLOR_YELLOW)==> Rolling back File Server$(COLOR_RESET)\n"
	helm rollback main-game-server -n $(MSA_NAMESPACE)

restart-main-game:
	@printf "$(COLOR_BLUE)==> Restarting File Server$(COLOR_RESET)\n"
	kubectl rollout restart deployment main-game-server -n $(MSA_NAMESPACE)

deploy-match-game: apply-secrets
	@printf "$(COLOR_BLUE)==> Deploying Match Game Server$(COLOR_RESET)\n"
	helm upgrade --install match-game-server ./helm/services/match-game-server \
		-n $(MSA_NAMESPACE)

uninstall-match-game:
	@printf "$(COLOR_YELLOW)==> Uninstalling Match Game Server$(COLOR_RESET)\n"
	helm uninstall match-game-server -n $(MSA_NAMESPACE)

rollback-match-game:
	@printf "$(COLOR_YELLOW)==> Rolling back Match Game Server$(COLOR_RESET)\n"
	helm rollback match-game-server -n $(MSA_NAMESPACE)

restart-match-game:
	@printf "$(COLOR_BLUE)==> Restarting Match Game Server$(COLOR_RESET)\n"
	kubectl rollout restart statefulset match-game-server -n $(MSA_NAMESPACE)

# ----------------------------------
# Traefik
# ----------------------------------
deploy-traefik:
	@printf "$(COLOR_BLUE)==> Deploying Traefik$(COLOR_RESET)\n"
	helm upgrade traefik traefik/traefik \
		--install \
		-n $(TRAEFIK_NAMESPACE) \
		--values helm/traefik/values.yaml \
		--skip-crds=false
	kubectl apply -f ./traefik/auth-middleware.yaml
	kubectl apply -f ./traefik/ws-middleware.yaml
	kubectl apply -f ./traefik/cors-middleware.yaml
	kubectl apply -f ./traefik/ingressroute.yaml

delete-traefik:
	@printf "$(COLOR_YELLOW)==> Uninstalling Traefik$(COLOR_RESET)\n"
	helm uninstall traefik -n $(TRAEFIK_NAMESPACE)

deploy-metallb:
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
	kubectl apply -f metallb/metallb-config.yaml

delete-metallb:
	kubectl delete -f metallb/metallb-config.yaml
	kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml


# ----------------------------------
# Monitoring (Grafana, Prometheus, Jaeger)
# ----------------------------------
deploy-loki:
	helm upgrade --install loki grafana/loki \
		--namespace monitor \
		-f ./helm/monitor/values-loki.yaml

delete-loki:
	helm uninstall loki -n monitor

deploy-grafana:
	helm upgrade --install grafana grafana/grafana \
		--namespace monitor \
		-f ./helm/monitor/values-grafana.yaml

delete-grafana:
	helm uninstall grafana -n monitor

deploy-jaeger:
	helm upgrade --install jaeger jaegertracing/jaeger \
		--namespace monitor \
		-f ./helm/monitor/values-jaeger.yaml

delete-jaeger:
	helm uninstall jaeger -n monitor

deploy-otel-collector:
	helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
		--namespace monitor \
		-f ./helm/monitor/values-otel-collector.yaml

delete-otel-collector:
	helm uninstall otel-collector -n monitor

deploy-alloy:
	helm upgrade --install my-alloy  grafana/alloy \
		--namespace monitor \
		-f ./helm/monitor/values-alloy.yaml

delete-alloy:
	helm uninstall my-alloy -n monitor

apply-alloy-config:
	kubectl create configmap alloy-config \
		--from-file=config.alloy=./helm/monitor/config.alloy \
		-n monitor \
		--dry-run=client -o yaml | kubectl apply -f -

restart-alloy:
	kubectl rollout restart daemonset/my-alloy -n monitor

deploy-prometheus:
	helm upgrade --install prometheus-stack \
		prometheus-community/kube-prometheus-stack \
		-f ./helm/monitor/values-prometheus.yaml \
		-n monitor

delete-prometheus:
	helm uninstall prometheus-stack -n monitor

deploy-elasticsearch:
	helm upgrade --install elasticsearch elastic/elasticsearch \
		--namespace monitor \
		-f ./helm/monitor/values-elasticsearch.yaml

delete-elasticsearch:
	helm uninstall elasticsearch -n monitor

deploy-cassandra:
	kubectl apply -f secrets/cassandra-secret.yaml -n monitor
	helm upgrade --install cassandra  \
		oci://registry-1.docker.io/bitnamicharts/cassandra \
		-n monitor -f ./helm/monitor/values-cassandra.yaml

delete-cassandra:
	helm uninstall cassandra -n monitor

deploy-all-monitoring: \
	deploy-loki \
	deploy-grafana \
	deploy-jaeger \
	deploy-alloy \
	apply-alloy-config \
	deploy-prometheus

delete-all-monitoring: \
	delete-loki \
	delete-grafana \
	delete-jaeger \
	delete-alloy \
	delete-prometheus

# ----------------------------------
# All-in-One
# ----------------------------------
install: \
	add-helm-repo \
	apply-local-path \
	create-namespace \
	apply-secrets \
	install-mariadb \
	install-redis \
	install-kafka

deploy-all: \
	deploy-user \
	deploy-auth \
	deploy-chat \
	deploy-file \
	deploy-main-game \
	deploy-match-game \
	deploy-traefik

reset:
	@printf "$(COLOR_YELLOW)==> Resetting environment$(COLOR_RESET)\n"
	helm uninstall mariadb-user     -n $(MSA_NAMESPACE) || true
	helm uninstall mariadb-auth     -n $(MSA_NAMESPACE) || true
	helm uninstall mariadb-chat     -n $(MSA_NAMESPACE) || true
	helm uninstall mariadb-main-game -n $(MSA_NAMESPACE) || true
	helm uninstall redis-user       -n $(MSA_NAMESPACE) || true
	helm uninstall redis-auth       -n $(MSA_NAMESPACE) || true
	helm uninstall redis-chat       -n $(MSA_NAMESPACE) || true
	helm uninstall redis-main-game  -n $(MSA_NAMESPACE) || true
	helm uninstall kafka            -n $(MSA_NAMESPACE) || true
	helm uninstall traefik          -n $(TRAEFIK_NAMESPACE) || true
	helm uninstall $(USER_SERVER_IMAGE) -n $(MSA_NAMESPACE) || true
	helm uninstall $(AUTH_SERVER_IMAGE) -n $(MSA_NAMESPACE) || true
	helm uninstall chat-server      -n $(MSA_NAMESPACE) || true
	helm uninstall file-server      -n $(MSA_NAMESPACE) || true
	helm uninstall main-game-server -n $(MSA_NAMESPACE) || true
	helm uninstall match-game-server -n $(MSA_NAMESPACE) || true
	helm uninstall grafana         -n $(MONITOR_NAMESPACE) || true
	helm uninstall jaeger          -n $(MONITOR_NAMESPACE) || true
	helm uninstall prometheus      -n $(MONITOR_NAMESPACE) || true
	helm uninstall loki            -n $(MONITOR_NAMESPACE) || true
	kubectl delete all,cm,secret,pvc -n $(MSA_NAMESPACE) || true
	kubectl delete all,cm,secret,pvc          || true

all: install