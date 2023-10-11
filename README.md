# tbnl-tf

## Setup

Start with local Terraform state, provision remote storage:

```sh
# Be sure to comment out the backend block in terraform code
terraform init
terraform apply --target=module.remote_state
```

Populate SSM parameter secrets via AWS console:


## Resources:

* https://tailscale.com/kb/1293/cloud-init/
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

## TODO

* ✅ Adapt and write kubeconfig to allow use outside of VM (using tailscale hostname as server)
* ✅ Script to download kubeconfig(s) from ssm
* ✅ GitOps repo, have Argo manage itself
* ✅ Split blue/green, propagate 'cluster name' into app-of-apps, controlling ingress hostnames etc.
* ✅ IAM policy and user for ESO
* ✅ Use helm for app-of-apps: Better propagating of values
* ✅ When using helm, make branch to track a variable. Use in cloud-init and propagate through apps
* ESO + secret 0
* Argo notifications
* Traefik stdout logging. https://qdnqn.com/how-to-configure-traefik-on-k3s/
* ✅ DNS entry for server on tailnet FQDN (`*.my-server.something-easy CNAME machine-name.blabla.ts.net`)
* ~~Cert manager for internal ingresses (lets-encrypt, DNS challenge)~~ (prod rate limit 50/wk, tricky when developing)
* Look into specifying the certificate to use: 

    * https://doc.traefik.io/traefik/https/tls/#tls-options
    * https://traefik.io/blog/https-on-kubernetes-using-traefik-proxy/

* Cloudflare tunnel
* LeafCloud server instead of DO

## V2

* Build image and upload to DO/LeafCloud
* Release flow: 

    * https://akuity.io/blog/introducing-kargo/ 
    * https://lifecycle.keptn.sh/?

* Analytics

    * https://blog.ossph.org/best-open-source-alternatives-to-google-analytics/
    * https://countly.com/product (postgres/mysql)
    * https://umami.is/docs/install (mongodb)
    * https://docs.ackee.electerious.com/#/docs/Get%20started#with-helm (mongodb)

* Mongodb free tiers

    * https://www.mongodb.com/pricing
    * https://azure.microsoft.com/en-us/blog/microsoft-azure-tutorial-how-to-integrate-azure-functions-with-mongodb/

## Findings

* Propagating variables through kustomize is hard/impossible

    * ApplicationSet allows some templating, picking up variables from the resource it acts on.
    * Passing annotations from Application to Application and then have replacement use it seems not possible. Setting commonAnnotations can't read from the metadata as an ApplicationSet can.

* Adding `spec.source.kustomize.patches` causes parent app-of-apps Application to alternate between sync/outOfSync. Somehow the kustomize block ends up in the actual parent Application's actual state.