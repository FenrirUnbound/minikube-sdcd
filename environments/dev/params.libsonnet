local params = std.extVar("__ksonnet/params");
local globals = import "globals.libsonnet";
local envParams = params + {
  components +: {
    // Insert component parameter overrides here
    api+: {
      k8sHostname: "192.168.99.100:8443",
    },
  },
};

{
  components: {
    [x]: envParams.components[x] + globals, for x in std.objectFields(envParams.components)
  },
}
