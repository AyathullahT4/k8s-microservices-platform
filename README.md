#  Kubernetes Microservices Platform

A containerized microservices platform on Kubernetes with ingress routing, health‑checked services, and overlay‑based config.  
Designed to mirror production‑grade deployment patterns while remaining fast to run locally.

---

## Overview

### Components
- **api-node** (Node.js) and **api-python** (Flask) — independent services with `/health checks`
- Kubernetes **Deployments** + ClusterIP Services
- **Ingress‑NGINX** with path rewrite (stable internal URLs, public `/api/*`)
- **Kustomize overlays**: base, dev (local), prod (resource limits + HPA)

### Why these choices
- **Ingress**: single L7 entrypoint; keeps service internals stable while evolving routes.
- **Kustomize**: drift control between environments without duplicating YAML.
- **Versioned images**: traceability; avoid `latest` in prod paths.
- **Local image policy (dev)**: `imagePullPolicy: Never` in dev overlay uses locally built images → zero external registry friction.

---

## Architecture

<img width="300" height="400" alt="image" src="https://github.com/user-attachments/assets/9df43ba4-d2d1-41ff-bef7-69b167c91c67" />




### Routing model
- **Public:** `app.local/api/node/health` → container `/health`
- **Public:** `app.local/api/python/health` → container `/health  `
  (Handled via regex + rewrite in the Ingress manifest.)
  
  <img width="940" height="43" alt="image" src="https://github.com/user-attachments/assets/54a10df5-1c5d-43d8-87c1-79848dc23d46" />

    
  <img width="940" height="45" alt="image" src="https://github.com/user-attachments/assets/068df35c-9e32-40e1-b08f-7fcebb6d843d" />
  



### Usage
```sh
#Cluster lifecycle
./scripts/start-kind.sh        # create local k8s; maps 8080->cluster:80
make images                    # build + load api-node/api-python into the cluster
make deploy-dev                # apply dev overlay (namespace: web)

# Access (leave port-forward running in another terminal if you didn't map host ports)
kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80

# Smoke checks
curl -s -H "Host: app.local" http://127.0.0.1:8080/api/node/health
curl -s -H "Host: app.local" http://127.0.0.1:8080/api/python/health

# Ops quick look
kubectl -n web get deploy,svc,ing
kubectl -n web rollout status deploy/api-node
kubectl -n web logs deploy/api-python --tail=50

### Tear down
  `./scripts/stop-kind.sh`
```

### Environments

**base/**
-  Deployments, Services, Ingress (regex + rewrite to /health paths)
-  Neutral image tags (set via overlays)

**overlays/dev**
-  Uses local images (imagePullPolicy: Never)
-  Tag example: api-node:v0.1.0, api-python:v0.1.0

**overlays/prod**
-  Resource requests/limits + HPA (CPU‑driven 2→5)
-  Image tags fixed (no latest)
-  Ready for registry‑based supply (CI to publish images)

⸻

### Operational notes

**Make targets**
-  `make images` — builds images and loads them into the local cluster
-  `make deploy-dev` — applies the dev overlay in web namespace
-  `make rollout / make logs` — quick status & last logs

**Config knobs**

| Variable | Default   | Purpose                      |
|----------|-----------|------------------------------|
| NS       | web       | Target namespace             |
| APP_HOST | app.local | Ingress host for local testing |

**Set at runtime:** 
  `make deploy-dev NS=staging`

⸻

### Security considerations
-  No secrets in repo; manifests are safe to publish.
-  Image policy: dev overlay uses local images; prod overlay intended for signed images from a registry.
-  Ingress: single point to add TLS and WAF in cloud environments.
-  Least privilege: default service accounts; no host mounts/capabilities.

⸻

### Cost awareness (for cloud runs)
-  Single ingress + small replicas; scale via HPA.
-  Split dev vs prod resources to keep idle cost minimal.
-  Externalize logs/metrics only when needed (e.g., managed Prometheus/Grafana).

⸻

### Troubleshooting (fast paths)

```sh
#  503 from ingress → no ready endpoints. Check:    
kubectl -n web get endpoints 
kubectl -n web get pods

#ImagePullBackOff (dev) → ensures dev overlay is active and images are loaded:  
make images && make deploy-dev

#Port 8080 busy (e.g., Jenkins) → stop it or use a different local port:  
sudo systemctl stop jenkins
kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8081:80

#Node not Ready → give CoreDNS a minute, then:  
ubectl -n kube-system get pods

```
⸻

### Why this exists
-  	Shows service decomposition with clear ingress strategy.
-  Uses environment overlays for controlled differences between dev and prod.
-  Demonstrates operability: health checks, rollout visibility, quick diagnostics.
-  Leaves a clear runway for CI/CD hardening without changing app code.
