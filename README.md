# High Availability Perl with Kubernetes

This presentation ([slides here](https://scottw.github.io/presentations/ha-perl-k8s/)) covers deploying a simple Redis-backed Mojolicious application in a Kubenetes cluster.

The application is a simple GET/PUT/DELETE HTTP API for retrieving, setting, and deleting keys in a Redis instance.

We'll deploy it first locally, using Docker, then in a local Kubernetes cluster using minikube.

## Sources

The examples in this presentation were inspired by the [Kubernetes Guestbook Example](https://github.com/kubernetes/kubernetes/tree/master/examples/guestbook/) as a base and also [this guide to minikube](https://medium.com/@claudiopro/getting-started-with-kubernetes-via-minikube-ada8c7a29620).
