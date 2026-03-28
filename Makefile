SHELL := /usr/bin/env bash

.PHONY: \
	bootstrap bootstrap-app bootstrap-backend bootstrap-cdk bootstrap-terraform bootstrap-packer \
	validate validate-app validate-backend validate-cdk validate-terraform validate-packer \
	login-ghcr resolve-image publish-image build-ami \
	doctor smoke verify-cdk verify-terraform verify-terraform-private \
	plan-terraform plan-terraform-private tunnel-terraform-private \
	deploy-cdk deploy-terraform deploy-terraform-private \
	cleanup-cdk cleanup-terraform cleanup-terraform-private

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

doctor:
	./scripts/doctor.sh $(ENV)

smoke:
	./scripts/smoke.sh $(TARGET) $(ENV) $(ENDPOINT)

verify-cdk:
	./scripts/verify-cdk.sh $(ENV) $(ENDPOINT)

verify-terraform:
	./scripts/verify-terraform.sh $(ENV) $(ENDPOINT)

verify-terraform-private:
	./scripts/verify-terraform-private.sh $(ENV) $(ENDPOINT)

plan-terraform:
	./scripts/plan-terraform.sh $(ENV) $(IMAGE)

plan-terraform-private:
	./scripts/plan-terraform-private.sh $(ENV) $(IMAGE)

tunnel-terraform-private:
	./scripts/tunnel-terraform-private.sh $(ENV)

deploy-cdk:
	./scripts/deploy-cdk.sh $(ENV) $(IMAGE)

deploy-terraform:
	./scripts/deploy-terraform.sh $(ENV) $(IMAGE)

deploy-terraform-private:
	./scripts/deploy-terraform-private.sh $(ENV) $(IMAGE)

cleanup-cdk:
	./scripts/cleanup-cdk.sh $(ENV) $(MODE)

cleanup-terraform:
	./scripts/cleanup-terraform.sh $(ENV) $(MODE)

cleanup-terraform-private:
	./scripts/cleanup-terraform-private.sh $(ENV) $(MODE)
