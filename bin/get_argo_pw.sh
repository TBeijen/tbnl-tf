#!/usr/bin/env bash
kubectl -n argocd get secret argocd-initial-admin-secret -o json |jq -r '.data.password | @base64d'
