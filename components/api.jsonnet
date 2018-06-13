local k = import "k.libsonnet";
local kservice = k.core.v1.service;
local kserviceSpec = kservice.mixin.spec;
local kservicePort = kserviceSpec.portsType;
local kdeployment = k.extensions.v1beta1.deployment;
local kdeploymentSpec = kdeployment.mixin.spec;
local kpodSpec = kdeploymentSpec.template.spec;
local kcontainer = kpodSpec.containersType;
local kport = kcontainer.portsType;
local king = k.extensions.v1beta1.ingress;
local kingSpec = king.mixin.spec;
local kroleBinding = k.rbac.v1beta1.roleBinding;
local env = std.extVar("__ksonnet/environments");
local paramComp = std.extVar("__ksonnet/params").components;
local params = paramComp.api;

local builderAccount = params.builderAccount;
local image = params.image;
local name = params.name;
local namespace = paramComp.screwdriver.namespace;
local podLabels = {
    "app": name,
    "svc": name,
};
local port = params.containerPort;
local replicas = params.replicas;

// service account
local sa = { "apiVersion": "v1", "kind": "ServiceAccount" }
  + k.core.v1.serviceAccount.mixin.metadata
      .withName(builderAccount)
      .withNamespace(params.builderNamespace);

// role binding
local roleBinding = {"apiVersion": "rbac.authorization.k8s.io/v1", "kind": "RoleBinding" }
  + kroleBinding.mixin.metadata
      .withName(params.builderAccount)
      .withNamespace(params.builderNamespace)
  + kroleBinding.mixin.roleRef
      .withApiGroup("rbac.authorization.k8s.io")
      .withKind("ClusterRole")
      .withName("admin")
  + kroleBinding
      .withSubjects([
        {
          "kind": "ServiceAccount",
          "name": params.builderAccount,
          "namespace": params.builderNamespace
        },
      ]);

// ingress
local apiIng = {"apiVersion": "extensions/v1beta1", "kind": "Ingress" }
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
local apiSvc = { "apiVersion": "v1", "kind": "Service", }
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
local sequelizeVol = "sequelize-storage";
local apiContainer = kcontainer
  .withName(name)
  .withImage(image)
  .withPorts(kport.new(port))
  .withEnv([
    kcontainer.envType.new("PORT", std.toString(port)),
    kcontainer.envType.new("URI", std.format("http://%s", params.name)),
    kcontainer.envType.new("ECOSYSTEM_UI", std.format("http://%s", paramComp.ui.hostname)),
    kcontainer.envType.new("ECOSYSTEM_STORE", std.format("http://%s", paramComp.store.name)),
    kcontainer.envType.new("DATASTORE_PLUGIN", "sequelize"),
    kcontainer.envType.new("DATASTORE_SEQUELIZE_DIALECT", "sqlite"),
    kcontainer.envType.new("DATASTORE_SEQUELIZE_STORAGE", "/tmp/sd-data/storage.db"),
    kcontainer.envType.new("EXECUTOR_PLUGIN", "k8s"),
    kcontainer.envType.new("K8S_HOST", params.k8sHostname),
    kcontainer.envType.new("K8S_JOBS_NAMESPACE", params.builderNamespace),
    kcontainer.envType.fromSecretRef("K8S_TOKEN", std.format("%s-token", builderAccount), "token"),
    kcontainer.envType.new("LAUNCH_VERSION", params.launcherVersion),
    kcontainer.envType.new("SECRET_WHITELIST", "[]"),
    kcontainer.envType.fromSecretRef("SCM_SETTINGS", "api-secrets", "scm-settings"),
    kcontainer.envType.fromSecretRef("SECRET_JWT_PRIVATE_KEY", "api-secrets", "jwt-private-key"),
    kcontainer.envType.fromSecretRef("SECRET_JWT_PUBLIC_KEY", "api-secrets", "jwt-public-key"),
  ])
  .withVolumeMounts([
    kcontainer.volumeMountsType.new(sequelizeVol, "/tmp/sd-data")
      .withReadOnly(false),
  ]);

local apiDeploy = { "apiVersion": "apps/v1", "kind": "Deployment", }
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
      .withContainers(apiContainer)
      .withVolumes([
        kpodSpec.volumesType.fromEmptyDir(sequelizeVol),
      ]);

k.core.v1.list.new([sa, roleBinding, apiSvc, apiDeploy, apiIng])