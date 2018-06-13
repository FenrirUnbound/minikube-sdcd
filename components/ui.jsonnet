local k = import "k.libsonnet";
local env = std.extVar("__ksonnet/environments");
local kdeployment = k.extensions.v1beta1.deployment;
local kdeploymentSpec = kdeployment.mixin.spec;
local kpodSpec = kdeploymentSpec.template.spec;
local kcontainer = kpodSpec.containersType;
local kport = kcontainer.portsType;
local kservice = k.core.v1.service;
local kserviceSpec = kservice.mixin.spec;
local kservicePort = kserviceSpec.portsType;
local king = k.extensions.v1beta1.ingress;
local kingSpec = king.mixin.spec;
local paramComp = std.extVar("__ksonnet/params").components;
local params = paramComp.ui;

local image = params.image;
local name = params.name;
local namespace = paramComp.screwdriver.namespace;
local podLabels = { "app": name, "svc": name };
local port = params.containerPort;
local replicas = params.replicas;

// ingress
local ing = {"apiVersion": "extensions/v1beta1", "kind": "Ingress" }
  + king.mixin.metadata
      .withNamespace(namespace)
      .withName(name)
  + kingSpec
      .withRules([
        {
          "host": params.hostname,
          "http": {
            "paths": [
              {
                "path": "/",
                "backend": {
                  "serviceName": name,
                  "servicePort": port
                }
              }
            ]
          }
        }
      ]);

// service
local svc = { "apiVersion": "v1", "kind": "Service", }
  + kservice.mixin.metadata
      .withNamespace(namespace)
      .withName(name)
      .withLabels({ "app": name })
  + kserviceSpec
      .withPorts([
        kservicePort.new(port, port)
      ])
      .withSelector(podLabels);

// container
local container = kcontainer
  .withName(name)
  .withImage(image)
  .withPorts(kport.new(port))
  .withEnv([
    kcontainer.envType.new("ECOSYSTEM_API", std.format("http://%s", paramComp.api.hostname)),
    kcontainer.envType.new("ECOSYSTEM_STORE", std.format("http://%s", paramComp.store.hostname)),
    kcontainer.envType.new("AVATAR_HOSTNAME", std.format("http://%s", params.avatarHostname)),
  ]);

// deployment
local deploy = { "apiVersion": "apps/v1", "kind": "Deployment", }
  + kdeployment.mixin.metadata
      .withNamespace(namespace)
      .withName(name)
      .withLabels(podLabels)
  + kdeploymentSpec.withReplicas(replicas)
  + kdeploymentSpec.selector
      .withMatchLabels(podLabels)
  + kdeploymentSpec.template.metadata
      .withLabels(podLabels)
  + kpodSpec
      .withContainers(container);

k.core.v1.list.new([deploy, svc, ing])