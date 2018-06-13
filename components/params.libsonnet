{
  global: {
    // User-defined global parameters; accessible to all component and environments, Ex:
    // replicas: 4,
  },
  components: {
    // Component-level parameters, defined initially from 'ks prototype use ...'
    // Each object below should correspond to a component in the components/ directory
    api: {
      builderAccount: "sd-build",
      builderNamespace: "screwdriver",
      containerPort: 80,
      hostname: "api.my.sd",
      image: "screwdrivercd/screwdriver:v0.5.361",
      // replace with actual IP by `minikube ip`; port should still be 8443
      k8sHostname: "minikube.info:8443",
      launcherVersion: "v4.0.102",
      name: "api",
      replicas: 1,
    },
    screwdriver: {
      name: "screwdriver",
      namespace: "screwdriver",
    },
    store: {
      containerPort: 80,
      hostname: "store.my.sd",
      image: "screwdrivercd/store:v3.1.2",
      name: "store",
      replicas: 1,
    },
    ui: {
      avatarHostname: "*.githubusercontent.com",
      containerPort: 80,
      hostname: "my.sd",
      image: "screwdrivercd/ui:v1.0.273",
      name: "ui",
      replicas: 1,
    },
  },
}
