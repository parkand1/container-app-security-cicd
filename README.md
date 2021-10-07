# `Container Application Security - CI/CD Pipeline using AWS for GitHub Actions`


# First time usage

1. Create CloudHSM [cluster](https://us-west-2.console.aws.amazon.com/cloudhsm/home?region=us-west-2#/clusters/create) in the cluster which you'll be deploying your application into. (5 minutes)

## Create the CloudHSM cluster in a VPC with at least 2 Private Subnets in different AZ's, or else you cannot create the Custom KMS Keystore.

2. Initialize the CloudHSM cluster, once it's created by clicking the `Initialize` button.

## Repeat the steps here twice to create 2 clusters
3. Download the CSR

```bash
export CLUSTER_ID=cluster-12345678

aws cloudhsmv2 describe-clusters --filters clusterIds=$CLUSTER_ID \
    --output text \
    --query 'Clusters[].Certificates.ClusterCsr' > ClusterCsr.csr 
```

4. Create a Private Key, create a self-signed certificate, and Sign the Cluster CSR.

```bash
openssl genrsa -aes256 -out customerCA.key 2048

openssl req -new -x509 -days 3652 -key customerCA.key -out customerCA.crt

openssl x509 -req -days 3652 -in ClusterCsr.csr \
    -CA customerCA.crt \
    -CAkey customerCA.key \
    -CAcreateserial \
    -out CustomerHsmCertificate.crt

aws cloudhsmv2 initialize-cluster --cluster-id $CLUSTER_ID \
    --signed-cert file://CustomerHsmCertificate.crt \
    --trust-anchor file://customerCA.crt
```

5. Create CloudHSM backed KMS [key](https://us-west-2.console.aws.amazon.com/kms/home?region=us-west-2#/kms/keys)

- Symmetric
- 


Create the ECR repository with the CloudHSM backed Key

```bash
aws ecr create-repository \
    --repository-name con317/app \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration '{"encryptionType":"KMS","kmsKey":"arn:aws:kms:us-west-2:key/19b4a2d3-0319-4afa-8sd9-123456}}'
```

6. Install gh, and enable Git Actions via CLI

## Instal the GH CLI tool
```bash
#Mac
brew install gh

#Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
sudo apt install gh
```

## Enable the GH worflows
```bash
gh workflow

gh workflow list
#CI  active  13960912
#CD  active  13960913

gh workflow enable 13960912
gh workflow enable 13960913
```

## Add the GH secrets for the github action

Using the [aws-credentials](https://github.com/aws-actions/configure-aws-credentials) Github action we will authenticate to our AWS account. To do this we have a few options.

- AWS Access-key, and AWS secret-key. (least secure)
- OIDC short lived IAM role


