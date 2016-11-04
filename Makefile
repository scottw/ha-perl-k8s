## local development
start-redis:
	docker run --name kv-redis -d -p 6379:6379 redis:alpine

stop-redis:
	docker stop kv-redis && docker rm kv-redis

assert-version:
	@if [[ "z$(VERSION)" == "z" ]]; then \
		echo "VERSION not set"; exit 1; \
	fi

build-mojo: assert-version
	docker build -t scottw/kv-mojo:$(VERSION) .

start-mojo:
	docker run --name kv-mojo -p 3000:3000 -d scottw/kv-mojo

stop-mojo:
	docker stop kv-mojo && docker rm kv-mojo

## Kubernetes targets
autoscale-app:
	kubectl autoscale rs kv-app --max 10

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
