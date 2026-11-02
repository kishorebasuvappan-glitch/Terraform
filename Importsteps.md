Writing

# Import Existing Azure Virtual Machine into Terraform using Import Blocks

This guide explains how to import an existing Azure Virtual Machine (`JKS-VM`) into Terraform state using Terraform import blocks.

## Prerequisites

- GitHub Codespaces
- Azure CLI installed
- Terraform 1.5 or later
- Azure subscription access
- AzureRM Terraform provider

## Step 1: Login to Azure

bash

```bash
az login --use-device-code
```

Set your Azure subscription:

bash

```bash
az account set --subscription "fcb39d30-fdd6-41a0-98f2-2c267c93c163"
```

Verify the subscription:

bash

```bash
az account show
```

## Step 2: Create Terraform configuration

Create a `main.tf` file with the Azure provider configuration.

hcl

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "fcb39d30-fdd6-41a0-98f2-2c267c93c163"
}
```

## Step 3: Add Terraform import block

Add the following import block to `main.tf`:

hcl

```hcl
import {
  to = azurerm_linux_virtual_machine.jks_vm

  id = "/subscriptions/fcb39d30-fdd6-41a0-98f2-2c267c93c163/resourceGroups/JKS-VM/providers/Microsoft.Compute/virtualMachines/JKS-VM"
}
```

For Windows VMs, use `azurerm_windows_virtual_machine` instead.

## Step 4: Generate Terraform configuration

Run:

bash

```bash
terraform init
```

Generate the resource configuration automatically:

bash

```bash
terraform plan -generate-config-out=generated.tf
```

Terraform generates a configuration file based on the existing Azure VM.

## Step 5: Review generated configuration

Open `generated.tf` and review the generated resource configuration.

Make sure the resource address matches the import block:

hcl

```hcl
resource "azurerm_linux_virtual_machine" "jks_vm" {
  # Generated VM configuration
}
```

Review and resolve any missing or conflicting configuration values.

## Step 6: Import the Azure VM

Run:

bash

```bash
terraform plan
```

Review the import operation and proposed changes.

Then execute:

bash

```bash
terraform apply
```

Confirm the operation when prompted.

## Step 7: Verify Terraform state

Check imported resources:

bash

```bash
terraform state list
```

Expected output:

text

```text
azurerm_linux_virtual_machine.jks_vm
```

View imported VM details:

bash

```bash
terraform state show azurerm_linux_virtual_machine.jks_vm
```

## Step 8: Validate Terraform configuration

Run:

bash

```bash
terraform fmt
terraform validate
terraform plan
```

Ideally, Terraform should report:

text

```text
No changes. Your infrastructure matches the configuration.
```

## Important Notes

- Terraform import blocks require Terraform 1.5 or later.
- `-generate-config-out` generates configuration for resources being imported when no matching resource configuration exists.
- Review the generated configuration before applying.
- Importing a VM does not automatically import related resources such as NICs, VNet, NSGs, public IPs, or managed disks.
- Back up your Terraform state before importing.
- Do not apply unexpected infrastructure changes.

## Reference

- Terraform Import Documentation: [https://developer.hashicorp.com/terraform/language/import](<https://developer.hashicorp.com/terraform/language/import>)
- AzureRM Provider: [https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs](<https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs>)
