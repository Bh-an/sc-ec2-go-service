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
| `docs/*` | Short-lived documentation updates |

## Pending Branch Protection Plan

> [!NOTE]
> This is the intended GitHub policy, but it is **not enforced yet**.

- `main` should require pull requests
- direct pushes to `main` should be blocked
- required checks should pass before merge
- `dev` should at least block force-push and deletion

Until GitHub protection is enabled, contributors should follow the same workflow manually: land work on `dev`, run checks, and merge to `main` through a PR.

## Before You Commit

```bash
make validate
```

This runs app tests, CDK build + synth, and Terraform validate.

> [!TIP]
> For scoped checks:

```bash
make validate TARGET=app
make validate TARGET=cdk
make validate TARGET=terraform
```
