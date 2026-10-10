.PHONY: test build run cluster apply delete

IMAGE ?= kubernetes-orchestration:training
CLUSTER ?= kube-training

test:
	python -m pytest -q

build:
	docker build -t $(IMAGE) .

run:
	docker run --rm -p 5000:5000 -e APP_ENV=formation $(IMAGE)

cluster:
	kind create cluster --name $(CLUSTER) --config kind/cluster.yaml

apply:
	kind load docker-image $(IMAGE) --name $(CLUSTER)
	kubectl apply -f manifests/00-namespace.yaml
	kubectl apply -f manifests/10-configmap.yaml
	kubectl apply -f manifests/20-deployment.yaml
	kubectl apply -f manifests/30-service.yaml

delete:
	kind delete cluster --name $(CLUSTER)
