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
	kubectl apply -f manifests/00-namespace.yaml
	@kubectl -n kube-training get secret ghcr-pull >/dev/null 2>&1 || { echo "Secret ghcr-pull manquant : suivre tp/TP02-ghcr-image-privee.md"; exit 1; }
	kubectl apply -f manifests/10-configmap.yaml
	kubectl apply -f manifests/20-deployment.yaml
	kubectl apply -f manifests/30-service.yaml
	kubectl -n kube-training rollout status deployment/flask-app

gateway:
	kubectl apply -f manifests/40-gateway.yaml
	kubectl apply -f manifests/50-httproute.yaml

delete:
	kind delete cluster --name $(CLUSTER)
