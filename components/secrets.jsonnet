local k = import "k.libsonnet";
local env = std.extVar("__ksonnet/environments");
local secrets = import "../secrets.libsonnet";
local params = std.extVar("__ksonnet/params").components;
local ksecret = k.core.v1.secret;

local namespace = params.screwdriver.namespace;
local saName = params.api.builderAccount;
local saSecretName = std.format("%s-token", saName);

local storeSecrets = ksecret.new("store-secrets")
  .withData({
      "jwt-public-key": std.base64(secrets.publicJwtKey),
  });

// not using "new" since it auto-includes the "data" field
local buildAccountSecrets = { apiVersion: "v1", kind: 'Secret' }
  + ksecret
      .withType("kubernetes.io/service-account-token")
  + ksecret.mixin.metadata
      .withName(saSecretName)
      .withNamespace(namespace)
      .withAnnotations({
        "kubernetes.io/service-account.name": saName
      });

local apiSecrets = ksecret.new("api-secrets")
  .withData({
      "jwt-public-key": std.base64(secrets.publicJwtKey),
      "jwt-private-key": std.base64(secrets.privateJwtKey),
      "scm-settings": std.base64(std.toString(secrets.scmSettings)),
  });

k.core.v1.list.new([buildAccountSecrets, storeSecrets, apiSecrets])