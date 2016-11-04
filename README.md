# High Availability Perl with Kubernetes

We'll make a little key-value storage application with a Redis backend using Mojolicious API.

The Mojo app will have a timer running, that after some random number of seconds between 0 and 60, the app will do a hard exit (POSIX::abort or something). Kubernetes should spawn a new container.

    $ minikube dashboard

Build and tag the application:

    $ make build-mojo VERSION=v2

Update the `deployment.yaml` file:

    containers:
        - name: kv-mojo
          image: scottw/kv-mojo:v2

Deploy:

    $ kubectl create -f deployment.yaml

View it:

    $ kubectl get pods

More detail and label selectors:

    $ kubectl get pods -o wide -l app=kv-mojo

View ReplicationSet:

    $ kubectl get rs
    NAME                DESIRED   CURRENT   READY     AGE
    kv-app-1624761082   3         3         3         6m

Autoscale the ReplicationSet:

    $ kubectl autoscale rs kv-app-1624761082 --max=10

How can you get to the pod? You need a service.

## services

A service is a proxy. It listens on a port (`port`) and it connects the incoming requests to `targetPort` to all services it finds using the **selector**.

## starting again

Using [Kubernetes Guestbook Example](https://github.com/kubernetes/kubernetes/tree/master/examples/guestbook/) as a base. Also [this guide](https://medium.com/@claudiopro/getting-started-with-kubernetes-via-minikube-ada8c7a29620).

Let's define our backend service (see `redis-service.yaml`), then run it:

    $ kubectl create -f redis-service-master.yaml

See what happened:

    $ kubectl get services
    NAME              CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
    kubernetes        10.0.0.1     <none>        443/TCP    4h
    kv-redis-master   10.0.0.236   <none>        6379/TCP   52s

(NOTE: no external IP exposed yet)

Let's deploy redis service now (see `redis-deployment.yaml`):

    $ kubectl create -f redis-deployment-master.yaml
    $ kubectl get deployments
    NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    kv-redis-master   1         1         1            1           34s

Let's deploy the front-end application now:

    $ kubectl create -f k8s/kv-mojo-deployment.yaml

and expose the service:

    $ kubectl expose deployment kv-app --type=NodePort

and find the service's IP:

    $ minikube service kv-app --url

FIXME: this doc needs some updating; see the Makefile.

## kubectl apply -f k8s/kv-mojo-deployment.yaml

## kubectl rollout undo deployment/kv-app
