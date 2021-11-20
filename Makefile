AWS_REGION ?= us-west-2
$(eval AWS_ACCOUNT_ID=$(shell aws sts get-caller-identity --query Account --output text))
$(eval REG=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com)

ecr-login:
	$(eval AWS_ACCOUNT_ID=$(shell aws sts get-caller-identity --query Account --output text))
	aws ecr get-login-password --region ${AWS_REGION} | docker login --password-stdin --username AWS "$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com"

install: create-ecr loggroup env task

create-ecr:
	aws ecr create-repository \
		--repository-name con317/app \
		--image-scanning-configuration scanOnPush=true

clean:
	aws ecr delete-repository \
		--repository-name con317/app \
		--force
	aws logs delete-log-group --log-group-name /ecs/con317/app


build: ecr-login
	cd app && docker build -t con317/app .
	docker tag go-arm64 $(REG)/con317/app:v1
	docker push $(REG)/fargate/con317/app:v1

clean-keys:
	rm -rf *.csr
	rm -rf *.crt
	rm -rf *.key
	rm -rf *.srl

loggroup:
	aws logs create-log-group --log-group-name /ecs/con317/app

env:
	ACCOUNT=$$(aws sts get-caller-identity --query 'Account' --output text) && echo "ACCOUNT_ID=$$ACCOUNT" > .env

task:
	export $$(xargs <.env) && envsubst < task-definition.json > .aws/task-definition.json

create-cf:
	aws cloudformation create-stack \
	--stack-name GithubOIDC \
	--template-body file://OIDC.yaml \
	--capabilities CAPABILITY_NAMED_IAM \
	--region us-west-2 \
	--parameters ParameterKey=GitHubOrg,ParameterValue=andrpar ParameterKey=RepositoryName,ParameterValue=container-app-security-cicd ParameterKey=OIDCProviderArn,ParameterValue=github