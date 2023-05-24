# Information

Folders below contains configuration code for specific subscriptions which needs to be run first to create necessary resources and assign required permissions for Terraform service principal so that it could be used later on in CI/CD for Infrastructure as Code. This all needs to be run **manually**.

> After run a storage account will be created in Azure subscription with management lock preventing removal of it or its containers. Besides that application with service principal will be created in Azure Active Directory with permissions requested for managing its applications and users/groups. Also, this service principal will be granted a custom created role in Azure Resource Manager at the subscription level. This role is using built-in Contributor role as a base with some allowed actions for management lock creation and ability to assign roles for security principals.

# Permissions

Permissions needed to run this configuration:

1. **Owner** for ARM Subscription or any other custom role with below permissions:
   - _Microsoft.Authorization/roleAssignments/read_
   - _Microsoft.Authorization/roleAssignments/write_
   - _Microsoft.Authorization/roleDefinitions/write_
   - _Microsoft.Authorization/locks/read_
   - _Microsoft.Authorization/locks/write_
   - _Microsoft.Resources/subscriptions/resourceGroups/read_
   - _Microsoft.Resources/subscriptions/resourceGroups/write_
   - _Microsoft.Security/advancedThreatProtectionSettings/read_
   - _Microsoft.Storage/storageAccounts/listKeys/action_
   - _Microsoft.Storage/storageAccounts/read_
   - _Microsoft.Storage/storageAccounts/write_
2. **Global Administrator** permission in Azure Active Directory is needed to grant administrator consent for application permissions initially or once such set of permisisons changes. Subsequently it's possible to use user account without any specific priviliges but such user should be an owner of all Azure AD resources (application registrations and service principals) to successfully apply code changes. This is covered by using variable _var.groups_ for existing groups members. If group membership changes, new users won't be able to work with configuration until someone from initial members (the ones which are already present in terraform state as Azure AD resources owners) applies code changes.

# Steps

## Run ONCE only!

> If there is already a storage account with terraform state file skip this section.
> **Global Administrator** or **Application Administrator** permisisons are required to apply changes related to Azure Active Directory.

Otherwise procced with next steps:

1. Verify that there were no environment variables set which start with _ARM_:

```powershell
ls env:\ARM*
```

2. Switch to the folder for the target subscription

```powershell
cd <folder name here>
```

3. Comment out all code in `terraform_backend.tf` file and save the changes.
4. Confirm that `az cli` is using correct user account with target subscription available by running next command

```powershell
az account show
```

Otherwise run the next commands and proceed with login to Azure. Also, tenant ID shoud be specified in case MFA is enabled for AAD account. If there are multiple subscriptions assosiated with AAD account then proper one should be selected:

```powershell
az account clear
az login --tenant <tenant id>
az account set --subscription <subscription id>
```

5. Check if variable "groups" was defined and specified Azure AD groups exist. Otherwise, either create them manualy or comment out all dependent resources.
6. Run next commands in the current directory

```powershell
terraform init
terraform plan -out=tfplan
```

7. Check and confirm that all resources are correct with their naming scheme. Otherwise, change default variables values to the proper ones and run for plan again. If all is ok then continue to the next command:

```powershell
terraform apply tfplan
```

8. Set environment variable _ARM_ACCESS_KEY_ by using value from the outputs section in the previous terraform run. Use the following command to set this value in powershell:

```powershell
$env:ARM_ACCESS_KEY="......access key value......"
```

9. Uncomment all code in `terraform_backend.tf` file, ensure the value of `storage_account_name` is equal to the one created one step above and save the changes.
10. Run and confirm state move to newly created storage container in Azure

```
terraform init
```

11. Now go to the [App Registrations](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps) in Azure Active Directory, find newly created application for Terraform "New Terraform application" -> ApiPermissions and grant consent for access.

12. Create a new client secret that will be used for automation deployments. Use it with necessary outputs from the terraform.

13. Lastly, login to SendGrid account using `Manage` button in the Azure Portal, setup 2FA authentication and create a token `<var.env>-management` (variable "env" value should be fetched from related configuration) with _full_ permissions only for `API Keys` and `Mail Send/Mail Send` scopes (api_keys.create, api_keys.delete, api_keys.read, api_keys.update, mail.send). Save the API token value in the Azure Key Vault created in the same configuration using `SendgridManagementAPIKey` as a secret name.

## Run for subsequent changes

1. Verify that there were no environment variables set which start with _ARM_:

```powershell
ls env:\ARM*
```

2. Switch to the folder for the target subscription

```powershell
cd <folder name here>
```

3. Confirm that `az cli` is using correct user account with target subscription available by running next command

```powershell
az account show
```

Otherwise run the next commands and proceed with login to Azure. Also, tenant ID shoud be specified in case MFA is enabled for AAD account. If there are multiple subscriptions assosiated with AAD account then proper one should be selected:

```powershell
az account clear
az login --tenant <tenant id>
az account set --subscription <subscription id>
```

4. Set environment variable _ARM_ACCESS_KEY_ by using value from the outputs section in the previous terraform run. Use the following command to set this value in powershell:

```powershell
$env:ARM_ACCESS_KEY="......access key value......"
```

5. Initialize terraform in the current directory

```powershell
terraform init
```

6. If the changes are to terraform service principal permissions then for a clean set existing security principal should be recreated by running

```powershell
terraform taint azuread_service_principal.terraform
```

7. Run next command to get list of changes which will be applied by terraform

```powershell
terraform plan -out=tfplan
```

8. Check and confirm that planned changes are correct and run

```powershell
terraform apply tfplan
```

9. If the changes are to terraform service principal permissions grant consent for those permissions.
10. Commit and push changes to this repository by creating a PR.
11. Grab a `:beer:`
