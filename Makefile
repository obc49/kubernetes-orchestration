.PHONY: test build run cluster apply gateway delete

CLUSTER ?= kube-training

test:
	python -m pytest -q

build:
	docker build -t kubernetes-orchestration:training .

run:
	docker run --rm -p 5000:5000 -e APP_ENV=formation kubernetes-orchestration:training

cluster:
	kind create cluster --config kind/cluster.yaml --wait 120s

apply:
	# Avant cette commande, modifiez manifests/20-deployment.yaml au TP03 avec l’image publiée au TP01.
	# Le déploiement initial sans ghcr-pull est volontaire pour observer ImagePullBackOff.
	kubectl apply -f manifests/00-namespace.yaml
	kubectl apply -f manifests/10-configmap.yaml
	kubectl apply -f manifests/20-deployment.yaml
	kubectl apply -f manifests/30-service.yaml

gateway:
	kubectl apply -f manifests/40-gateway.yaml
	kubectl apply -f manifests/50-httproute.yaml

delete:
	kind delete cluster --name $(CLUSTER)
