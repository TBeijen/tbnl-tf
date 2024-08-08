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

Force sync ESO secret

```sh
kubectl annotate es my-es force-sync=$(date +%s) --overwrite
```

Get Cloudflare access service_account

```sh
terraform show -json | jq '.values.root_module.child_modules[] | select(.address == "module.tbnl") | .resources[] | select(.address = "module.tbnl.cloudflare_access_service_token.tbnl_health_checks")'
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
* ✅ Provision example secret as part of cloudserver
* Argo notifications
* Argo trigger on GitHub webhook
* ✅ Traefik stdout logging. https://qdnqn.com/how-to-configure-traefik-on-k3s/
* ✅ DNS entry for server on tailnet FQDN (`*.my-server.something-easy CNAME machine-name.blabla.ts.net`)
* ~~Cert manager for internal ingresses (lets-encrypt, DNS challenge)~~ (prod rate limit 50/wk, tricky when developing)
* ✅ Monitoring, options:

    * New Relic: https://newrelic.com/pricing (would like to try DataDog free tier, but 1d retention vs 8d NR is big drawback: https://www.datadoghq.com/pricing/)
    * Grafana cloud
    * https://thenewstack.io/how-to-monitor-kubernetes-k3s-using-telegraf-and-influxdb-cloud/
    * Honeycomb

* Look into specifying the certificate to use: 

    * https://doc.traefik.io/traefik/https/tls/#tls-options
    * https://traefik.io/blog/https-on-kubernetes-using-traefik-proxy/

* ✅ Cloudflare tunnel
* ✅ DNS blue/green toggling
* Separate CF Access Application for health check
* Set timeout on ArgoCD failed sync (e.g. namescape create overlooked. Keeps waiting for something that will never happen)
* Application pipelines (blog, anno2003)
* Argo project for user applications
* ✅ Application www referencing separate gitops repo
* ✅ LeafCloud/Hetzner/Arubacloud server instead of DO
* ✅ K3S Resource tuning

    * https://devops.stackexchange.com/questions/16070/where-does-k3s-store-its-var-lib-kubelet-config-yaml-file

* GH issues cloudflare tunnel helm chart

    * named ports not supported
    * Misconfig ends up with all pods crashloop. No maxUnavail? Or health check?

* Filter out traefik ping logs from OTEL collector

    * Or configure in Traefik when available: https://github.com/traefik/traefik/pull/9633

* Cloudflare metrics dropped by NR prometheus agent

    * https://docs.newrelic.com/docs/infrastructure/prometheus-integrations/install-configure-prometheus-agent/troubleshooting-guide/
    * `k -n newrelic exec newrelic-newrelic-prometheus-agent-0 -- wget -O - 'localhost:9090/api/v1/targets?state=dropped' 2>/dev/null |jq`

* ✅ Configure system/kubelet reserved memory (evict pods before vm saturated)

    * https://github.com/k3s-io/k3s/issues/5488
    * https://devops.stackexchange.com/questions/16070/where-does-k3s-store-its-var-lib-kubelet-config-yaml-file

* ArgoCD notification improvements

    * Set context.argocdUrl
    * Only send notification when app has actually changed: https://github.com/argoproj/argo-cd/issues/12169
    * Customize template

* ArgoCD bouncer improvements

    * Bolt on, currently too aggresive. Quirks when argo tries to refresh target state while pods are restarting. Only need reload when cm actually changes.
    * Consider https://github.com/stakater/Reloader (still bolt on, lots of moving parts)
    * Consider ArgoCD helm chart, which has mechanism built in via cm sha checksum annotation on deployments

## V2

* Build image and upload to DO/LeafCloud
* Talos:

    * https://github.com/hetznercloud/awesome-hcloud

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

* Talos/SUSE on Hetzner

     * https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner
     * https://github.com/hcloud-talos/terraform-hcloud-talos?tab=readme-ov-file
     * https://www.talos.dev/v1.6/talos-guides/install/cloud-platforms/hetzner/
     * https://www.reddit.com/r/kubernetes/comments/1b8wb22/there_are_only_12_binaries_in_talos_linux/

## Findings / Issues

* Propagating variables through kustomize is hard/impossible

    * ApplicationSet allows some templating, picking up variables from the resource it acts on.
    * Passing annotations from Application to Application and then have replacement use it seems not possible. Setting commonAnnotations can't read from the metadata as an ApplicationSet can.

* Adding `spec.source.kustomize.patches` causes parent app-of-apps Application to alternate between sync/outOfSync. Somehow the kustomize block ends up in the actual parent Application's actual state.
* Honeycomb API key only seems to work on US API, not EU. Can't find anything about geo in UI.
* Externalsecret that was originally misconfigured, remains in state Degraded, even if it has synced succesfully
