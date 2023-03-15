# Replace <INSERT_COMPARTMENT_NAME> with actual compartment name
export compname=<INSERT_COMPARTMENT_NAME>
export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`

# Replace <INSERT_DB_NAME> with actual DB name.
export DBname=<INSERT_DB_NAME>
# Save DB OCID in variable based on name(case sensitive)
export ATPocid=`oci db autonomous-database list --compartment-id $Compocid --query "data[?contains(\"display-name\",'$DBname')]"|jq -r ".[].id"`

# Get object storage namespace 
export namespace=`oci os ns get|jq -r ".data"`
export bucketname=Wallet_$DBname

# Create bucket with object events enabled
#Optionally Configure bucket notifications to notify users
export Bucketocid=`oci os bucket create --compartment-id $Compocid --name $bucketname --namespace-name $namespace --object-events-enabled true |jq -r ".data.id"`

#Set Wallet filename
export filename=Wallet_$DBname.zip
echo $filename
export wallet_password=<SUPER_SECRET_PASSWORD>

#Generate Wallet
oci db autonomous-database generate-wallet --autonomous-database-id $ATPocid --file $filename --password $wallet_password
 
# Upload to object store bucket. Overwrite existing file using --force option
oci os object put -bn $bucketname --file $filename -ns $namespace --force
