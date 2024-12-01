
# Prerequisites

- [Prerequisites](#prerequisites)
  - [1. Using Cloudshell (Option 1)](#1-using-cloudshell-option-1)
  - [2. Using Local Linux Machine (Option 2)](#2-using-local-linux-machine-option-2)
  - [3. Create AWS Access Key and Secret Key](#3-create-aws-access-key-and-secret-key)
  - [4. Configure AWS CLI](#4-configure-aws-cli)
  - [5. AWS Secret Key Configuration for Terraform](#5-aws-secret-key-configuration-for-terraform)
  - [6. SSH Access to Virtual Machines (Optional)](#6-ssh-access-to-virtual-machines-optional)


## 1. Using Cloudshell (Option 1)

1. Ensure that you have [setup your AWS Cloud Shell](https://docs.aws.amazon.com/cloudshell/latest/userguide/welcome.html) environment.

2. Log in to AWS [Cloud Shell](https://docs.aws.amazon.com/cloudshell/latest/userguide/welcome.html#how-to-get-started).

   > **Cloud Shell Timeout**
   >
   > The machine that provides the Cloud Shell session is temporary, and is recycled after your session is inactive for 20-30 minutes.

If you prefer to run the code on a local bash terminal, then proceed to [Option 2](#2-using-local-linux-machine-option-2).

## 2. Using Local Linux Machine (Option 2)

To use a local Linux machine, do the following:

1. Ensure that you have installed [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. Ensure that you have installed [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## 3. Create AWS Access Key and Secret Key

[Create access keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user_manage_add-key.html) for your AWs user.

Save the keys .csv file in a secure location.

## 4. Configure AWS CLI

[Configure the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html#getting-started-quickstart-new) by supplying the access key and secret key:

```bash
aws configure
```

Sample output:

```bash
aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-west-2
Default output format [None]: json
```

## 5. AWS Secret Key Configuration for Terraform

The terraform codes in this lab require the `aws_access_key` and `aws_secret_key` to be configured. Set the following environment variables for terraform:

```bash
export TF_VAR_aws_access_key="your_access_key"
export TF_VAR_aws_secret_key="your_secret_key"
```

## 6. SSH Access to Virtual Machines (Optional)

All labs are configured with serial console access to virtual machines. Alternatively, you can use SSH to access the virtual machines. In order to use SSH, you need to have an SSH key pair.

1\. Generate the SSH key pair.

```bash
export private_key_path=/<your-user-directory>/.ssh/id_rsa
ssh-keygen -t rsa -b 2048 -m PEM -f "$private_key_path"
```

2\. Set the environment variable `TF_VAR_public_key_path` to the public key path.

```bash
export TF_VAR_public_key_path=/<your-user-directory>/.ssh/id_rsa.pub
```

`TF_VAR_public_key_path` will be used by terraform to import the public key to AWS.

