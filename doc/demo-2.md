# Perl in Kubernetes

    $ minikube status
    $ minikube dashboard (may take a moment; try --url if not working)
    $ kubectl get nodes, deployments, pods, services

Let's look at the app (`kv-mojo`). Also at `Dockerfile`. Ok, let's build the app:

    $ make build-app KV_VERSION=v1

Normally, we'd build the app here, and then we'd push it to Docker Hub or to gcp.io, but Docker can also find the image if it's local and tagged.

## Kubernetes

Now let's look at what it takes to run our app in Kubernetes. Also note that I deleted the Redis image. I did this because Kubernetes will go get it for me, as with all images I describe.

(Look at `k8s/redis-service-master.yaml`)

Let's look at the Redis service. Remember that when we deploy a pod into a cluster, nothing can access it until we stand up a service object, which can act as a load balancer, a firewall, a proxy, or an application router. Our service will only allow other pods in the cluster to access it.

Our service has a name `kv-redis-master`. This service will get its own DNS entry inside of Kubernetes, meaning we can use that name in our application or as a configuration variable as a well-known hostname.

Let's run this service:

    $ kubectl create -f k8s/redis-service-master.yaml

So we have a service proxy running now.

(Look at `k8s/redis-deployment-master.yaml`)

Now let's look at deploying our Redis backend. We'll call the backend `kv-redis-master`, which matches our service name, but doesn't need to. You can add `deployment` or something else like that, but you generally list things by their type and so that would be redundant.

Services get DNS entries, but all Kubernetes objects need names so we can see what they're for when we list them on the command line or in the dashboard. Let's deploy this deployment now:

    $ kubectl create -f k8s/redis-deployment-master.yaml

Let's see what we've done now:

    $ kubectl get services
    $ kubectl get deployment
    $ kubectl get pods

(reload dashboard)

We only have 1 pod running, where our Redis container lives.

Let's run our API application (ensure KV_VERSION=v1):

    $ kubectl create -f k8s/kv-app-deployment.yaml
    $ kubectl get pods

## Implicit Service

Let's list our services again; remember, we only have the Redis service available so our app can get to it.

    $ kubectl get services

We also need to expose our app to the world. Kubernetes has a few ways to do this. I'm going to use the simplest way to expose them I know, which is the `expose` command. You can do this declaratively also, by the way.

    $ kubectl expose deployment kv-app --type NodePort
    $ kubectl get services (notice the "<nodes>" for EXTERNAL IP)

See now that `kv-app` is exposed via something called nodes. This just means that the nodes themselves have opened up some ephemeral ports. We can ask about them:

    $ minikube service kv-app --url

So while `expose` is easy to do, it makes it a little hard to work with. It's really for demos like this. Plus we're sort of using a VM inside of a VM, so there's a lot of routing going on anyway.

Anyway, now we know it's IP address and can curl it:

    $ curl --include --request GET http://$(minikube service kv-app --url)/foo

## Manual Scaling

We can see now we have 3 pods. We can update the yaml file and ask for more pods:

(edit and apply, then get pods)

## Availability

Remember that one `POST /die` route? Let's kill one of the applications and watch a pod restart.

    $ while true; do clear; kubectl get pods; sleep 1; done

    $ curl --include --request POST /die

Notice the version header also. I added this so we could see what we're hitting.

## Rollouts

Now I realize that I have a bug, that I should remove that route and roll out version 2. Let's do that.

(make a new version without `POST /die`)
(update k8s/kv-app-deployment.yaml)

    $ kubectl apply -f k8s/kv-app-deployment.yaml
    $ kubectl get pods

(hit with curl, look at version)

## Dashboard

    $ minikube dashboard

look at dashboard:
* drill into a pod's logs
* look at the nodes' health

## Autoscaling

In Kubernetes, each controller has a role. Application scaling is handled by what is called a ReplicationSet, usually created by your deployment for you. We can list the replicationsets:

    $ kubectl get rs
    NAME                        DESIRED   CURRENT   READY     AGE
    kv-app-3657952125           3         3         3         26s
    kv-redis-master-564512877   1         1         1         26s

and then tell our app's RS to scale automatically for us:

    $ kubectl autoscale rs kv-app-3657952125 --max=10

This will set the RS maximum to burst to 10 pods as needed. You can also control the heuristics to determine when to scale (e.g., CPU, memory pressure, etc.)