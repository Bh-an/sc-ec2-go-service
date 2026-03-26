SHELL := /usr/bin/env bash

.PHONY: \
	bootstrap bootstrap-app bootstrap-backend bootstrap-cdk bootstrap-terraform bootstrap-packer \
	validate validate-app validate-backend validate-cdk validate-terraform validate-packer \
	login-ghcr resolve-image publish-image build-ami \
	deploy-cdk deploy-terraform cleanup-cdk cleanup-terraform

bootstrap:
	./scripts/bootstrap.sh $(or $(TARGET),all)

bootstrap-app:
	./scripts/bootstrap.sh app

bootstrap-backend:
	./scripts/bootstrap.sh backend

bootstrap-cdk:
	./scripts/bootstrap.sh cdk

bootstrap-terraform:
	./scripts/bootstrap.sh terraform

bootstrap-packer:
	./scripts/bootstrap.sh packer

validate:
	./scripts/validate.sh $(or $(TARGET),all)

validate-app:
	./scripts/validate.sh app

validate-backend:
	./scripts/validate.sh backend

validate-cdk:
	./scripts/validate.sh cdk

validate-terraform:
	./scripts/validate.sh terraform

validate-packer:
	./scripts/validate.sh packer

login-ghcr:
	./scripts/login-ghcr.sh

resolve-image:
	./scripts/resolve-image.sh $(IMAGE)

publish-image:
	./scripts/publish-image.sh $(TAG)

build-ami:
	./scripts/build-ami.sh $(ENV)

deploy-cdk:
	./scripts/deploy-cdk.sh $(ENV) $(IMAGE)

deploy-terraform:
	./scripts/deploy-terraform.sh $(ENV) $(IMAGE)

cleanup-cdk:
	./scripts/cleanup-cdk.sh $(ENV) $(MODE)

cleanup-terraform:
	./scripts/cleanup-terraform.sh $(ENV) $(MODE)
