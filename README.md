# Screwdriver.CD with Minikube

## Prerequisites

* [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/)
* ksonnet v0.11.0
* jsonnet v0.10.0

As a forewarning, this readme assumes your minikube is configured to the default settings. 

## Usage

In order to deploy 

1. Starting minikube
1. Connect Screwdriver API with minikube API
1. Configuring the API secrets
1. Optional: modify your `/etc/hosts` file for convenient CNAME use

### Starting Minikube

```
# start minikube if it's not already running
$ minikube start

# enable ingress for a simplified ingress solution
$ minikube addons enable ingress
```

### Connect Screwdriver API with Minikube API

```
# get the minikube ip
$ minikube ip
192.168.99.xxx

# in the environments/default/params.libsonnet file
...
  components +: {
    api+: {
      k8sHostname: "192.168.99.xxx:8443",
    },
  }
...
```

### Configure Secrets

At a minimum, you will need a JWT private-public key pair and a configured SCM strategy.

These secrets can be created in a `secrets.libsonnet` file at the root of the repository. As an example, you may review the `example.secrets.libsonnet` file to see a more concrete example.

#### JWT Keys

```
# generating a private jwt private-public pair on a mac

# creates a private key
$ openssl genrsa -out jwt.pem 4096

# creates the related public key
$ openssl rsa -in jwt.pem -pubout -out jwt.pub

# inclue the values in your secrets.libsonnet file
{
    "publicJwtKey": "...",
    "privateJwtKey": "..."
}
```

#### SCM Configurations

Depending on the SCM Services, creating an OAuth application will be different. For example, [this page describes how to provision one with Github.com](https://developer.github.com/apps/building-oauth-apps/creating-an-oauth-app/)

It is highly recommended to read up on the [Configuring Screwdriver API](https://docs.screwdriver.cd/cluster-management/configure-api) documentation.

Here is a sample of what values to include in the `secrets.libsonnet` file.

```
# include the values in your secrets.libsonnet file
{
    scmSettings: {
        "scm_strategy_name": {
            plugin: "github",
            config: {
                "oauthClientId": "replace_with_your_oauth_client_id",
                "oauthClientSecret": "replace_with_your_oauth_client_secret",
                "username": "github.com_username",
                "email": "email_address",
                "secret": "secret_for_github.com_webhook_auth",
            }
        },
        "scm_strategy_name_2": {
            ...
        }
    }
}
```

### Optional: Edit /etc/hosts

Although Kubernetes allows you to define a localized DNS server, doing so may be too cumbersome for some to attempt. As an alternative, you may edit your `/etc/hosts` file so that you can have a similar workflow.

```
# get the local IP address of minikube
$ minikube ip
192.168.99.xxx

# append the ip address to your /etc/hosts file
$ echo '192.168.99.xxx my.sd api.my.sd' >> /etc/hosts

# open your browser and go to http://my.sd
```


### Deploy

Ensure that your `kubectl` configuration is pointing to your minikube cluster. Once that's confirmed, you can simly run the `ks apply default` command.

```
# deploy it to the minikube cluster
$ ks apply default
```

## Limitations

Minikube runs a single-node Kubernetes cluster inside a VM on your laptop. Since it's an incredibly simplified cluster, it is a great way to get familiar with a Kubernetes environment.

Since it's running a single-node cluster, there are some limitations that should be called out that may not be obvious.

### Build Resources

By default, a build will run with a `Low CPU`/`Low Memory` resource requirement. As of writing, this requires 2 CPU cores & 2GB of RAM. If your minikube cluster isn't allocated enough resources, builds will not dequeue until the cluster has enough capacity to allow the builds to run. 

There are 3 ways to resolving this:

1. Increase the size of your minikube cluster. This may be difficult if your local workstation does not have the hardware capacity for it.
1. Explicitly define your builds with a `Micro CPU`/`Micro Memory` annotation. See [Annotations page](https://docs.screwdriver.cd/user-guide/configuration/annotations) for specific details.
1. Override the default values for `K8S_CPU_LOW`/`K8S_MEMORY_LOW` resource definitions. See [Executor Plugin](https://docs.screwdriver.cd/cluster-management/configure-api#configuration) section.
