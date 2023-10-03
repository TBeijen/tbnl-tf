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

* Adapt and write kubeconfig to allow use outside of VM (using tailscale hostname as server)
* Script to download kubeconfig(s) from ssm
* GitOps repo, have Argo manage itself
* Split blue/green, propagate 'cluster name' into app-of-apps, controlling ingress hostnames etc.
* IAM policy and user for ESO
* ESO
* Argo notifications
* DNS entry for server on tailnet FQDN (`*.my-server.something-easy CNAME machine-name.blabla.ts.net`)
* Cert manager for internal ingresses (lets-encrypt, DNS challenge)
* Cloudflare tunnel
* LeafCloud server instead of DO
