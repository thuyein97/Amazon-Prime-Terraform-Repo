## infra (Terraform)

This folder represents the **Infrastructure repo**.

### What it does
- Provisions AWS network + Kubernetes cluster (VPC + EKS managed node group).
- Produces **cluster metadata outputs** (API endpoint, cluster name, OIDC issuer, etc).
- Writes/updates a single **bridge file** in the GitOps repo: `../gitops/clusters/cluster-config.yaml`.
- Bootstraps ArgoCD onto the new cluster and applies the app-of-apps entrypoint in `argocd/root-app.yaml`.

### Repo
- `https://github.com/thuyein97/terraform-eks-cluster.git`

### Pipeline order
1. `terraform init`
2. `terraform apply`
3. Terraform generates/updates `gitops/clusters/cluster-config.yaml`
4. Install/upgrade ArgoCD (Helm recommended) and apply `argocd/root-app.yaml`

### Quick start
```bash
cd infra
terraform init
terraform apply
```

Useful overrides:

```bash
terraform apply \
  -var="aws_region=ap-southeast-1" \
  -var="cluster_name=bankapp-eks" \
  -var="environment=prod"
```

### Bridge file (handshake)
Terraform writes cluster metadata here:
- `../gitops/clusters/cluster-config.yaml`


