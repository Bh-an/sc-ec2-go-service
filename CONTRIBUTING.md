# Contributing

## Commits

[Conventional Commits](https://www.conventionalcommits.org/) format:

```
type(scope): short description
```

| Rule | Detail |
|------|--------|
| Types | `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci` |
| Scopes | `app`, `infra`, `cdk`, `terraform`, `ci`, `ops` |
| Subject | Imperative mood, under 72 chars, no trailing period |
| Granularity | One logical change per commit |

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Stable, tagged releases |
| `dev` | Integration and release prep |
| `ci-cd` | Workflow and automation changes only |

## Before You Commit

```bash
make validate
```

This runs app tests, CDK build + synth, and Terraform validate. For scoped checks:

```bash
make validate TARGET=app
make validate TARGET=cdk
make validate TARGET=terraform
```
