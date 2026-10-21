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

- **PR / push** (`terraform-ci.yml`): `fmt`, `validate`, tflint, Trivy config scan, and
  shellcheck on GitHub-hosted runners. No secrets or Azure credentials, so it is safe for fork PRs.
- **main** (`terraform-apply.yml`): plan on the self-hosted runner, then apply that exact
  plan in the `production` environment (requires approval), then sync outputs to
  `exit-app` repo variables.

Provider versions are pinned in the committed `envs/prod/.terraform.lock.hcl`
(CI uses `-lockfile=readonly`). After bumping providers, regenerate it with:

```bash
terraform -chdir=envs/prod providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=darwin_amd64
```

Postgres and Key Vault have `prevent_destroy`; removing either requires editing the module first.

Key Vault is private (private endpoint only). See
[bootstrap/GITHUB_SECRETS.md](bootstrap/GITHUB_SECRETS.md) for runner bootstrap.

## App repo

`git@github.com:marcusgunnebo/exit-app.git`
