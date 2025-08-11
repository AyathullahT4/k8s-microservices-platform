SHELL := /bin/bash
NS ?= web
APP_HOST ?= app.local

kind-up:
	kind create cluster --name kdev || true

kind-down:
	kind delete cluster --name kdev || true

ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl -n ingress-nginx wait deploy/ingress-nginx-controller --for=condition=Available --timeout=180s

images:
	docker build -t api-node:latest services/api-node
	docker build -t api-python:latest services/api-python
	kind load docker-image api-node:latest --name kdev
	kind load docker-image api-python:latest --name kdev

deploy-dev:
	kubectl create ns $(NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl -n $(NS) apply -k k8s/overlays/dev
	kubectl -n $(NS) get deploy,svc,ing

deploy-prod:
	kubectl create ns $(NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl -n $(NS) apply -k k8s/overlays/prod
	kubectl -n $(NS) get deploy,svc,ing,hpa

logs:
	kubectl -n $(NS) logs deploy/api-node --tail=50
	kubectl -n $(NS) logs deploy/api-python --tail=50

rollout:
	kubectl -n $(NS) rollout status deploy/api-node
	kubectl -n $(NS) rollout status deploy/api-python

pf:
	kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80

clean:
	kubectl -n $(NS) delete -k k8s/overlays/dev --ignore-not-found=true || true
	kubectl -n $(NS) delete -k k8s/overlays/prod --ignore-not-found=true || true
