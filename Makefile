SHELL := /usr/bin/env bash

.PHONY: bootstrap validate validate-app validate-cdk validate-terraform publish-image deploy-cdk deploy-terraform

bootstrap:
	./scripts/bootstrap.sh

validate:
	./scripts/validate.sh

validate-app:
	./scripts/validate.sh app

validate-cdk:
	./scripts/validate.sh cdk

validate-terraform:
	./scripts/validate.sh terraform

publish-image:
	./scripts/publish-image.sh $(TAG)

deploy-cdk:
	./scripts/deploy-cdk.sh $(ENV) $(IMAGE)

deploy-terraform:
	./scripts/deploy-terraform.sh $(ENV) $(IMAGE)
