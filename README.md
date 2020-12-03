# Cloud Development Environment

This Terraform project creates an instance, a bastion host and a NAT gateway.

**Figure 1.** *diagram of Google Cloud resources*

![architecture diagram](./diagram.png)

## Set up the environment

1. Set the project, replace `YOUR_PROJECT` with your project ID:

```
PROJECT=YOUR_PROJECT
```

```
gcloud config set project ${PROJECT}
```

2. Configure the environment for Terraform:

```
gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

3. Create a terraform.tfvars file with required variables
```
members_osadminlogin = ["user:me@example.com"]
```

## Configure remote backend

1. Configure Terraform [remote backend](https://www.terraform.io/docs/backends/types/gcs.html) for the state file.

```
BUCKET=${GOOGLE_PROJECT}-terraform
gsutil mb gs://${BUCKET}

PREFIX=cloud-dev/state
```

```
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket     = "${BUCKET}"
    prefix     = "${PREFIX}"
  }
}
EOF
```

## Run Terraform

```
terraform init
terraform apply
```

## Testing

Establish ssh tunnel between VM and laptop

with user
```
gcloud compute ssh cloud-dev
```

or via service account
```
ssh -i output/ssh/ansible_sa_private_key.pem sa_123456789@1.2.3.4
```

## OS Login 

https://cloud.google.com/compute/docs/instances/managing-instance-access

https://cloud.google.com/compute/docs/tutorials/service-account-ssh

https://cloud.google.com/iam/docs/impersonating-service-accounts

https://alex.dzyoba.com/blog/gcp-ansible-service-account


https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam

https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/service_account_access_token

## Ansible Setup

https://alex.dzyoba.com/blog/gcp-ansible-service-account/

## VS Code Setup

https://medium.com/andcloudio/setting-up-development-environment-on-google-cloud-dd91b619cc80


## Cleanup

1. Exit the ssh sessions:

```
exit
```

2. Remove all resources created by terraform:

```
terraform destroy
```
