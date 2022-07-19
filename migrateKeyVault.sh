#!/bin/bash
sourceKeyVault="$1"
targetKeyVault="$2"

if [[ -z $sourceKeyVault || -z $targetKeyVault ]]
then
  echo "please provide source and target keyvault names"
  exit 1
fi

echo "source keyvault is ==> $sourceKeyVault"
echo "target keyvault is ==> $targetKeyVault"

function migrateSecrets(){
  echo "migrating secrets from $sourceKeyVault to $targetKeyVault"
  secrets=($(az keyvault secret list --vault-name $sourceKeyVault --query "[].id" -o tsv))
  for secret in "${secrets[@]}"; do
    secretName=$(echo "$secret" | sed 's|.*/||')
    secretCheck=$(az keyvault secret list --vault-name $targetKeyVault --query "[?name=='$secretName']" -o tsv)
    if [ -n "$secretCheck" ]
    then
      echo "A secret with name $secretName already exists in $targetKeyVault"
    else
      echo "Copying $secretName to KeyVault: $targetKeyVault"
      secret=$(az keyvault secret show --vault-name $sourceKeyVault -n $secretName --query "value" -o tsv)
      az keyvault secret set --vault-name $targetKeyVault -n $secretName --value "$secret" >/dev/null
    fi
 done
}

function migrateCertificates(){
  echo "migrating certificates from $sourceKeyVault to $targetKeyVault"
  certs=($(az keyvault certificate list --vault-name $sourceKeyVault --query "[].id" -o tsv))
  for cert in "${certs[@]}"; do
    certName=$(echo "$cert" | sed 's|.*/||')
    certCheck=$(az keyvault certificate list --vault-name $targetKeyVault --query "[?name=='$certName']" -o tsv)
    if [ -n "$certCheck" ]
    then
      echo "A certificate with name $certName already exists in $targetKeyVault"
    else
      echo "Copying $certName to KeyVault: $targetKeyVault"
      az keyvault secret download --file ${certName}.pfx --vault-name $sourceKeyVault --name $certName --encoding base64
      az keyvault certificate import --file ${certName}.pfx --name $certName --vault-name $targetKeyVault
    fi
 done

}
#### main script ####
#migrateSecrets
migrateCertificates
