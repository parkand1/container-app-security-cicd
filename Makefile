AWS_REGION ?= us-west-2
$(eval AWS_ACCOUNT_ID=$(shell aws sts get-caller-identity --query Account --output text))
$(eval REG=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com)

ecr-login:
	$(eval AWS_ACCOUNT_ID=$(shell aws sts get-caller-identity --query Account --output text))
	aws ecr get-login-password --region ${AWS_REGION} | docker login --password-stdin --username AWS "$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com"

clean: clean-ecr clean-keys

clean-ecr:
	aws ecr delete-repository \
		--repository-name con317/app \
		--force

build: ecr-login
	cd app && docker build -t con317/app .
	docker tag go-arm64 $(REG)/con317/app:v1
	docker push $(REG)/fargate/con317/app:v1

clean-keys:
	rm -rf *.csr
	rm -rf *.crt
	rm -rf *.key
	rm -rf *.srl


create-cf:
	aws cloudformation create-stack \
	--stack-name GithubOIDC \
	--template-body file://OIDC.yaml \
	--capabilities CAPABILITY_NAMED_IAM \
	--region us-west-2 \
	--parameters ParameterKey=GitHubOrg,ParameterValue=jonahjon ParameterKey=RepositoryName,ParameterValue=container-app-security-cicd ParameterKey=OIDCProviderArn,ParameterValue=github