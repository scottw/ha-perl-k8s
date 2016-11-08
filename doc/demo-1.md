# Local Perl with Docker

Our application is a simple Mojolicious application. We have a redis helper here, that connects to a Redis instance. Where is the Redis connection? The constructor looks for an environment variable `MOJO_REDIS_URL` and will connect to that.

Let's get our local Docker environment running. I'll be using a tool called `minikube` for this:

    $ minikube status
    (turn on VirtualBox, watch VM building)
    $ minikube start
    $ eval "$(minikube docker-env)"
    $ minikube status
    $ docker images
    $ docker ps

This way we could run a local Redis, then run our app locally as well setting `MOJO_REDIS_URL` to point to our local Redis instance. If Redis were running elsewhere, in a cloud or in a staging environment, we just change the environment variable.

The application is 100% non-blocking. Here is the GET handler:

    get '/:key' => sub {
        my $c = shift;
        $c->render_later;

        $c->delay(
            sub {
                $c->redis->get($c->param('key'), shift->begin);
            },

            $c->redis_response
        );
    };

This `delay()` function here creates an IO::Loop::Delay object and passes everything it receives to the `steps()` function. Each subroutine runs only when the previous subroutine has finished its work. In the meantime, control passes back to the event loop for other routines to run.

The `PUT` and `DELETE` handlers are almost identical, but invoking the appropriate Redis call to set or delete the key and its value.

Finally, I have a little suicide handler here, which if you `POST` to it, it will send the application a `TERM` signal. This is for part of the demo later.

If I run a local Redis instance, I could connect to it. Run Redis:

    $ docker run --name kv-redis -d -p 6379:6379 redis:alpine

(16s to pull and run from my house)

Let's check it:

    $ docker ps | grep redis
    $ nc $(minikube ip) 6379

Cool, we can talk to Redis.

Now run our app:

    MOJO_REDIS_URL=redis://$(minikube ip):6379 ct ./kv-mojo get /foo

Let's set a value:

    MOJO_REDIS_URL=redis://$(minikube ip):6379 ct ./kv-mojo get -M PUT -c 'bar' /foo

and retrieve it:

    MOJO_REDIS_URL=redis://$(minikube ip):6379 ct ./kv-mojo get /foo

Delete it:

    MOJO_REDIS_URL=redis://$(minikube ip):6379 ct ./kv-mojo get -M DELETE /foo

That's local development and our application.
