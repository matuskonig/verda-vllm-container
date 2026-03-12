# verda-vllm-container

This repository contains Terraform configuration for provisioning and managing
VLLM serving Docker container on [Verda](https://verda.com) cloud provider.

## Prerequisites

- [Terraform](https://www.terraform.io/) installed on your machine
- Cloud API credentials from Verda cloud console
- HuggingFace access token

## Setup

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Configure Environment Variables

The following environment variables are required:

| Variable              | Description         |
| --------------------- | ------------------- |
| `VERDA_CLIENT_ID`     | Verda client ID     |
| `VERDA_CLIENT_SECRET` | Verda client secret |
| `TF_VAR_hf_token`     | Hugging Face token  |

You can store these variables in a `.env` file and load them with:

```bash
set -a && source .env && set +a
```

### 3. Plan and Apply

Preview the changes:

```bash
terraform plan
```

Apply the configuration:

```bash
terraform apply
```

This command will provision the infrastructure

## Explore Available Options

To help you decide on the infrastructure, you can run:

```bash
./get_verda_data.sh
```

This script retrieves available hardware options and their pricing.
