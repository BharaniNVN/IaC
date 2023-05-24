#!/usr/bin/env bash

set -euo pipefail

if command -v sudo >/dev/null 2>&1; then
    SUDO='sudo'
    BINDIR="/usr/local/bin"
else
    SUDO=''
    BINDIR="$HOME/bin"
fi

[ ! -d "$BINDIR" ] && mkdir -p "$BINDIR"

current_version=$(terraform version | grep -Eo -m 1 '[0-9]+.[0-9]+.[0-9]+' || true)
if [[ "$current_version" != "${TERRAFORM_VERSION:-$current_version}" ]];
then
    [ ! -f "$BINDIR/terraform_$TERRAFORM_VERSION" ] && \
    echo "==> Installing terraform $TERRAFORM_VERSION" \
    && curl -Os "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip -qq "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && $SUDO mv -f terraform "$BINDIR/terraform_$TERRAFORM_VERSION" \
    && rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    terraform="$BINDIR/terraform_$TERRAFORM_VERSION"
else
    terraform=$(which terraform)
fi

cd "$RELEASE_PRIMARYARTIFACTSOURCEALIAS/drop/$INFRA_CONFIG_PATH"

export TF_IN_AUTOMATION=1
export TF_CLI_ARGS="-no-color"
PARALLELISM=${PARALLELISM:-10}
(( $PARALLELISM != 10 )) && echo "##vso[task.logissue type=warning]Terraform will make #$PARALLELISM concurrent operations."
[[ "${DESTROY:-false}" == "true" ]] && export TF_CLI_ARGS_plan="-destroy"

set -a && source <(printenv | awk -F= '!/^BUILD_|^SYSTEM[_=]|^AGENT_|^RELEASE_|^LEIN_|^GOROOT[_=]|^ANDROID_|^GRADLE_|^OLDPWD=|^MSDEPLOY_|^JAVA_HOME|^ANT_|^USER=|^AZURE_HTTP_|^VSTS_PROCESS_|^agent.jobstatus=|^DOTNET_|^PATH=|^VSTS_AGENT_|^PWD=|^INPUT_ARGUMENTS=|^CONDA=|^LANG=|^SHLVL=|^M2_HOME=|^HOME=|^REQUESTEDFORID=|^CHROME_|^TASK_|^ENDPOINT_URL_|^_=|^TF_|^INFRA_CONFIG_PATH=/ {n=index($0,"="); $2=substr($0,n+1); NF=2; printf "TF_VAR_%s=\47%s\47\n",tolower($1),$2}')  && set +a

if [[ "${PRINTENV:-false}" == "true" ]];
then
    echo -e "############################################"
    echo -e "########## ENVIRONMENT VARIABLES ###########"
    echo -e "############################################"
    printenv
fi

$terraform --version
rm -rf .terraform
#az --version
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID --output none
az account set --subscription $ARM_SUBSCRIPTION_ID
#az account show
$terraform init -upgrade=true -backend-config="storage_account_name=$TF_STORAGE_ACCOUNT" -backend-config="container_name=$TF_STORAGE_CONTAINER"
$terraform plan -input=false -out=tfplan | tee plan.output
all_res=`awk '/Plan:/ {sum=$2+$5+$8} END {print sum=="" ? 0 : sum}' plan.output`
if  [[ $all_res != 0 ]] || [[ "${FORCE:-false}" == "true" ]] && [[ "${PLANONLY:-false}" == "false" ]];
then
    d_res=`awk '/Plan:/ {print $8}' plan.output`
    f_res=`awk '/.*module.*(module.prepare_configuration.azurerm_storage_blob.configuration).*(must be replaced)/ {print $2}' plan.output`
    f_res_count=`echo -n "$f_res" | grep -c '^' || :`
    if [[ $d_res -eq $f_res_count ]] || [[ "${FORCE:-false}" == "true" ]];
    then
        $terraform apply -parallelism=$PARALLELISM tfplan
    else
        echo "##vso[task.logissue type=error]Please check the terraform plan and approve destruction of resource(s) by setting release variable FORCE to true!"
        exit 1
    fi
fi