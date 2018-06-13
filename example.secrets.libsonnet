{
    publicJwtKey: "-----BEGIN PUBLIC KEY-----\n .....\n-----END PUBLIC KEY-----\n",
    privateJwtKey: "-----BEGIN RSA PRIVATE KEY-----\n .....\n-----END RSA PRIVATE KEY-----\n",
    scmSettings: {
        "github_com": {
            plugin: "github",
            config: {
                "oauthClientId": "replace_with_your_oauth_client_id",
                "oauthClientSecret": "replace_with_your_oauth_client_secret",
                "username": "github.com_username",
                "email": "email_address",
                "secret": "secret_for_github.com_webhook_auth",
            }
        }
    }
}