# Deploy x number of shell VMs in VMware Cloud on AWS

This example shows how to programmatically deploy a set amount of "shell" VMs (no operating system installed) in a VMware Cloud on AWS Software-defined Data Center (SDDC) via [HashiCorp Terraform](https://www.terraform.io). The original use case for this template was simple scalability testing, but it could also be used as a starter infrastructure as code template for your SDDC.

## Getting Started

### Prerequisites

1. [HashiCorp Terraform](https://www.terraform.io/downloads.html)
1. [VMware Cloud on AWS console](https://vmc.vmware.com/console/sddcs)

### Deploy

1. `cp ./terraform.tfvars.example ./terraform.tfvars`
1. Update values in ./terraform.tfvars as appropriate
1. [`terraform init`](https://www.terraform.io/docs/commands/init.html)
1. [`terraform plan`](https://www.terraform.io/docs/commands/plan.html)
1. [`terraform apply`](https://www.terraform.io/docs/commands/apply.html)

### Destroy

* `terraform destroy`

## Additional Resources

* [Getting started with HashiCorp Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
* [HashiCorp Terraform source code](https://github.com/hashicorp/terraform)
* [VMware Cloud on AWS documentation](https://docs.vmware.com/en/VMware-Cloud-on-AWS/index.html)
