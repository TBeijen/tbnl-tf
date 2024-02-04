# tbnl-tf

## Setup

Start with local Terraform state, provision remote storage:

```sh
# Choose (or create) environment
cd environments/dev

# Be sure to comment out the backend block in terraform code
terraform init

# Create state bucket (might need two attempts because of 409 on PutBucketVersioning)
terraform apply --target=module.tbnl.module.terraform_state

# Activate state configuration by uncommenting
# Answer 'yes' on question to copy state
terraform init

# Bootstrap ssm secrets
terraform apply --target=module.tbnl.module.secret

# Populate secrets in AWS console or using AWS CLI
#
# Now providers can be configured using secret
terraform apply
```

Populate SSM parameter secrets via AWS console:


## Resources:

* https://tailscale.com/kb/1293/cloud-init/
* https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deploy-tunnels/tunnel-permissions/
* Tunnel supports ingress paths: https://github.com/cloudflare/cloudflared/issues/286#issuecomment-753038216
* Argo:

    * https://argo-cd.readthedocs.io/en/release-2.8/operator-manual/installation/
    * https://argo-cd.readthedocs.io/en/release-2.8/operator-manual/declarative-setup/#manage-argo-cd-using-argo-cd

```sh
kubectl create namespace argocd
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.4/manifests/install.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/TBeijen/tbnl-gitops/main/argocd/install.yaml

# Obtain configured secrets
aws ssm get-parameters-by-path --path '/tbnl-tf/prod/' --with-decryption --recursive --output json
```

Cloudflare tunnel
```sh
cloudflared tunnel create prod-poc-1
cat /Users/tibobeijen/.cloudflared/b7456fee-908e-43cc-b96f-92dbfe60167f.json
```

## TODO

* ✅ Adapt and write kubeconfig to allow use outside of VM (using tailscale hostname as server)
* ✅ Script to download kubeconfig(s) from ssm
* ✅ GitOps repo, have Argo manage itself
* ✅ Split blue/green, propagate 'cluster name' into app-of-apps, controlling ingress hostnames etc.
* ✅ IAM policy and user for ESO
* ✅ Use helm for app-of-apps: Better propagating of values
* ✅ When using helm, make branch to track a variable. Use in cloud-init and propagate through apps
* ✅ ESO + secret 0
* Provision example secret as part of cloudserver
* Argo notifications
* Traefik stdout logging. https://qdnqn.com/how-to-configure-traefik-on-k3s/
* ✅ DNS entry for server on tailnet FQDN (`*.my-server.something-easy CNAME machine-name.blabla.ts.net`)
* ~~Cert manager for internal ingresses (lets-encrypt, DNS challenge)~~ (prod rate limit 50/wk, tricky when developing)
* Monitoring, New Relic: https://newrelic.com/pricing (would like to try DataDog free tier, but 1d retention vs 8d NR is big drawback: https://www.datadoghq.com/pricing/)
* Look into specifying the certificate to use: 

    * https://doc.traefik.io/traefik/https/tls/#tls-options
    * https://traefik.io/blog/https-on-kubernetes-using-traefik-proxy/

* ✅ Cloudflare tunnel
* DNS blue/green toggling
* Application pipelines (blog, anno2003)
* LeafCloud server instead of DO

## V2

* Build image and upload to DO/LeafCloud
* Cilium:

    * https://medium.com/@ebrar/single-node-k3s-installation-with-cilium-and-hubble-f4cbaacd9176
    * https://github.com/seanmwinn/cilium-k3s-demo
    * https://gist.github.com/iul1an/95587a087dbc6bf06bfdaf6c60eb1d3e

* NeuVector

    * https://medium.com/btech-engineering/introduction-to-neuvector-4defb6168eae
    * https://ranchermanager.docs.rancher.com/v2.6/integrations-in-rancher/neuvector
    * https://www.suse.com/neuvector/

* Kubescape

* Release flow: 

    * https://akuity.io/blog/introducing-kargo/ 
    * https://lifecycle.keptn.sh/?
    * Promoting releases (KCD2023): https://github.com/rcarrata/kcd23ams-gitops-patterns/blob/main/demos/pattern6/README.md

* Analytics

    * https://blog.ossph.org/best-open-source-alternatives-to-google-analytics/
    * https://countly.com/product (postgres/mysql)
    * https://umami.is/docs/install (mongodb)
    * https://docs.ackee.electerious.com/#/docs/Get%20started#with-helm (mongodb)

* Mongodb free tiers

    * https://www.mongodb.com/pricing
    * https://azure.microsoft.com/en-us/blog/microsoft-azure-tutorial-how-to-integrate-azure-functions-with-mongodb/

* Multi-tenancy

    * ArgoCD

        * Needs: https://argo-cd.readthedocs.io/en/stable/user-guide/projects/
        * Application in any namespace: https://argo-cd.readthedocs.io/en/stable/operator-manual/app-any-namespace/
        * Appset in any namespace (beware of exfil secrets via scm): https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Appset-Any-Namespace/
        * 2 angles: K8S resources, ArgoCD (GUI) RBAC. To leverage ArgoCD RBAC need IDP having admin & team-x users.

    * ESO:

        * https://external-secrets.io/v0.5.7/guides-multi-tenancy/
        * SecretStores per namespace. Needs IAM roles to restrict access to ssm prefixes. eso-system & eso-team-t roles. How to protect secret in namespace? Or restrict its ability (assume role x) w/o needing an access key per namespace?

* ArgoCD multi-user RBAC

    * Via keycloak?
    * Passwordless keycloak
    * Possible to backup/migrate keycloak users? -> Seed users via something like https://candrews.integralblue.com/2021/09/users-and-client-secrets-in-keycloak-realm-exports/

## Findings

* Propagating variables through kustomize is hard/impossible

    * ApplicationSet allows some templating, picking up variables from the resource it acts on.
    * Passing annotations from Application to Application and then have replacement use it seems not possible. Setting commonAnnotations can't read from the metadata as an ApplicationSet can.

* Adding `spec.source.kustomize.patches` causes parent app-of-apps Application to alternate between sync/outOfSync. Somehow the kustomize block ends up in the actual parent Application's actual state.
