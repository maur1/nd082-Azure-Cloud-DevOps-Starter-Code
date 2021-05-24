# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
A Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone the repository


### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
1. Log in your Azure account
 ```bash
az login
 ```

2. Deploy azure policy 
 - Create a policy definition

```bash
az policy definition create --name tagging-policy --rules tagging-policy.rules.json --params tagging-policy.parm.json
```

- Create a policy assignment

```bash
az policy assignment create --name tagging-policy --policy tagging-policy --params "{ \"tagName\": 
    { \"value\": \"YourTag\"  } }"
```

- Check if your policy creation is successful

```bash
az policy assignment list
```

3.  Create the premade packer server image by running
```bash
packer build
```


4. Use the terraform variables to customize the infrastructure
Following properties are available to set:
```
prefix, location, num_of_vms, username, password

```
User name and password must be set as env variables:

```bash
export TF_VAR_username=$(pass db_username)
export TF_VAR_password=$(pass db_password)
```

5. Run Terraform to deploy your infrastructure
```bash
terraform init
```

```bash
terraform plan 
```

```bash
terraform apply
```



