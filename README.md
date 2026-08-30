# Exit Infrastructure

Terraform for the Exit Shopify app on Azure (Exit subscription).

## Layout

```
exit-infra/
  bootstrap/       # one-time Azure setup scripts
  envs/prod/       # production environment
  modules/         # reusable Terraform modules
```

## Bootstrap

```bash
./bootstrap/bootstrap.sh
GITHUB_ORG=marcusgunnebo ./bootstrap/setup-github-oidc.sh
cp envs/prod/backend.hcl.example envs/prod/backend.hcl
# edit backend.hcl and terraform.tfvars
cd envs/prod && terraform init -backend-config=backend.hcl && terraform apply
```

See [bootstrap/GITHUB_SECRETS.md](bootstrap/GITHUB_SECRETS.md) for CI secrets.

## CI/CD

- **PR**: `terraform plan`
- **main**: `terraform apply` + sync outputs to `exit-app` repo variables

## App repo

`git@github.com:marcusgunnebo/exit-app.git`
