#List all Autonomous DB name and OCID in compartment
export compname=<INSERT_PRIMARY_COMPARTMENT_NAME>
export comp_id=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
oci db autonomous-database list --compartment-id $comp_id --all --query "data[].[id,\"display-name\"]" --output table

#save OCID in variable based on name(case sensitive) string
export ADBName=<INSERT_PRIMARY_DB_NAME>
export ATPocid=`oci db autonomous-database list --compartment-id $comp_id --query "data[?contains(\"display-name\",'$ADBName')]"|jq -r ".[].id"`

#get required destination standby DB region
export DestRegion=<INSERT_STANDBY_CITY_NAME>
export ociregionname=`oci iam region list --query "data[?contains(\"name\",'$DestRegion')]"|jq -r ".[].name"`
echo $ociregionname

#get destination region subnet
export networkcompname=<INSERT_TARGET_NETWORK_COMPARTMENT_NAME>
export ncomp_id=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[]| select(.name == \"${networkcompname}\") | .id"`

#Set remote subnet name
export remotesubnetname=<INSERT_TARGET_SUBNET_NAME>
#save remote subnetocid
# Imp - --region flag to query remote region. 
export remsubnet_ocid=`oci network subnet list --compartment-id $ncomp_id --all --region $ociregionname --query "data[?contains(\"display-name\",'$remotesubnetname')]"|jq -r ".[].id"`

#Uncomment next 3 lines if the target remote region compartment is different from primary DB
#export compname=<INSERT_TARGET_COMPARTMENT_NAME>
#export comp_id=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
#echo $comp_id
#Create ADB DG
export standbyDBName=<INSERT_STANDBY_DB_DISPLAY_NAME>
export remoteADBocid=`oci db autonomous-database create-adb-cross-region-data-guard-details  --compartment-id $comp_id --display-name $standbyDBName --source-id $ATPocid --subnet-id $remsubnet_ocid --region $ociregionname|jq -r ".data.id"`

while true
do
export status=`oci db autonomous-database get --autonomous-database-id $remoteADBocid|jq -r '.data["lifecycle-state"]'`
echo "Current DB State is $status, sleeping for 10 seconds"
echo "Ctrl+C to exit"
sleep 10
done
