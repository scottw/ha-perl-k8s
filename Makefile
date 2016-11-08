## Docker build target
assert-version:
	@if [[ "z$(KV_VERSION)" == "z" ]]; then \
		echo "KV_VERSION not set"; exit 1; \
	fi

build-app: assert-version
	docker build -t scottw/kv-mojo:$(KV_VERSION) --build-arg KV_VERSION=$(KV_VERSION) .

## Kubernetes deploy targets
start-app:
	kubectl create -f k8s/redis-service-master.yaml
	kubectl create -f k8s/redis-deployment-master.yaml
	kubectl create -f k8s/kv-app-deployment.yaml
	kubectl expose deployment kv-app --type NodePort
	minikube service kv-app --url

stop-app:
	kubectl delete -f k8s/kv-app-deployment.yaml
	kubectl delete service kv-app
	kubectl delete -f k8s/redis-deployment-master.yaml
	kubectl delete -f k8s/redis-service-master.yaml
