#!/usr/bin/env bash
kubectl -n argocd port-forward service/argocd-server 8080:80
