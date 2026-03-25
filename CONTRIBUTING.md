# Contributing

## Commit Standard

Use Conventional Commits:

```text
type(scope): short description
```

- Allowed types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`
- Common scopes: `app`, `infra`, `cdk`, `terraform`, `ci`
- Keep the subject imperative, under 72 characters, and without a trailing period
- Do not add AI attribution lines

## Branching

- `main` is the stable branch
- `dev` is the shared integration and release-prep branch

## Before You Commit

Run the checks relevant to the files you changed:

```bash
cd app && go test ./... && go build ./cmd/server
cd infra/terraform && terraform validate
cd infra/cdk && go build .
```
