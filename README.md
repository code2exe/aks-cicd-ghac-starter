# GitHub Actions <> AKS Starter App

This project was built to demonstrate how to setup CI/CD with GitHub Actions and Azure Kubernetes Services. 

It contains a simple NodeJS app which will be packaged into a container image and deployed into an AKS Cluster using GitHub Actions. 

It also contains the Terraform script which will create the base infrastructure which consists of an Azure Container Registry instance and the AKS Cluster (with monitoring enabled). 
It will also create the various GitHub Actions Secrets as seen in `infra/secrets.tf` which would enable our workflows execute successfully.


> This project assumes that you have an active Azure subscription and a GitHub account with Azure Cli and Terraform installed on your PC

## How To Use It

You will fork this repository into your GitHub account and then clone it to your PC and navigate to the `infra` directory:

```bash
git clone https://github.com/<username>/aks-cicd-ghac-starter.git
cd aks-cicd-ghac-starter/infra
```

You will create a `terraform.tfvars` file and fill in the following details: 

```bash
subscription_id = "<Subscription ID>"
tenant_id = "<Tenant ID>"
client_id = "<Client ID>"
client_secret = "<Client Secret>"
prefix = "<Prefix>"
location = "<Location>"
pa_token = "<GitHub Personal Access Token>"
container_name = "<Container Name>"
repo = "<Repository Name>"
repo_fullname = "<'Username' or 'Org_Name'>/<Repository Name>"
```

To retrieve the `subscription_id` , `tenant_id` , `client_id` , and `client_secret` :

Firstly, login to the Azure CLI using:

```
az login
```

Once logged in - it's possible to list the Subscriptions associated with the account via:

```
az account list
```

The output (similar to below) will display one or more Subscriptions - with the **`id`** field being the **`subscription_id`** field referenced above.

```
[
  {
    "cloudName": "AzureCloud",
    "id": "xxxxxxxxxxxxxxxxx",
    "isDefault": true,
    "name": "PAYG Subscription",
    "state": "Enabled",
    "tenantId": "10000000-0000-0000-0000-000000000000",
    "user": {
      "name": "user@example.com",
      "type": "user"
    }
  }
]
```

Should you have more than one Subscription, you can specify the Subscription to use via the following command:

```
az account set --subscription="xxxxxxxxxxxxxxxx"
```

We can now create the Service Principal which will have permissions to manage resources in the specified Subscription using the following command:

```
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/xxxxxxxxxxx"
```

This command will output 5 values:

```
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "azure-cli-2017-06-05-10-41-15",
  "name": "http://azure-cli-2017-06-05-10-41-15",
  "password": "0000-0000-0000-0000-000000000000",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

These values map to the Terraform variables like so:

- `appId` is the `client_id` defined above.
- `password` is the `client_secret` defined above.
- `tenant` is the `tenant_id` defined above.

The `pa_token` can be created on the Developer Settings of your GitHub Account. 

> Depending on your needs, you may want tp create fine-grained tokens and give it permissions to ‘Read and write’ Secrets only

![Untitled](docs/images/Untitled.png)


Now that you have set up those values, you will do the following in the `infra` directory

```bash
terraform init
terraform plan
terraform apply
```

When the infrastructure has been created, you can then visit your repository and run the workflow on the Actions tab as shown below:

![Untitled](docs/images/Untitled%201.png)

> Note: This workflow is also configured to run when there are changes to any of the `app/**` and `infra/k8s/**` paths
>

