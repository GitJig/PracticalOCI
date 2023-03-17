# This script assumes unique compartment name within tenancy. 
# Adjust for duplicate compartments accordingly 
# Replace  Compartment name in the line below.
export compname=<REPLACE_COMPARTMENT_NAME>
export comp_id=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
echo $comp_id

# This script assumes unique compartment name within tenancy. 
# Adjust for duplicate compartments accordingly 
# Provide name of compartment containing target subnet for ADB creation
export networkcompname=<REPLACE_COMPARTMENT_NAME>
export ncomp_id=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${networkcompname}\") | .id"`
oci network subnet list --all --compartment-id $ncomp_id --query "data[].[id,\"display-name\"]" --output table

#Search for subnet with name containing string. 
#Replace <REPLACE_SUBNET_NAME> with actual subnet name
export subnetname=<REPLACE_SUBNET_NAME>
export subnet_id=`oci network subnet list --all --compartment-id $ncomp_id --query "data[?contains(\"display-name\",'$subnetname')]"|jq -r ".[].id"`
echo $subnet_id

export password=<SUPER_SECRET_PASSWORD>
export dbname=<INSERT_DB_NAME>
export charset=AL32UTF8
export computecount=2
export computemodel=ECPU 
export storageintbs=1
export dbworkload=OLTP
export dispname=<INSERT_Display_NAME>
export autoscale=TRUE
export mtlsconn=false
export license=LICENSE_INCLUDED
export maintainencesched=REGULAR
export waitforstate=PROVISIONING

#Create Primary ADB with private endpoint
export $ADBocid=`oci db autonomous-database create --compartment-id $comp_id \
--admin-password $password --character-set $charset \
--compute-count $computecount --compute-model $computemodel \
--data-storage-size-in-tbs $storageintbs --db-name $dbname \
--db-workload $dbworkload --display-name $dispname \
--is-auto-scaling-enabled $autoscale --is-mtls-connection-required $mtlsconn \
--license-model $license --maintenance-schedule-type $maintainencesched \
--subnet-id $subnet_id --wait-for-state $waitforstate | jq -r ".data.id"`

while true
do
export status=`oci db autonomous-database get --autonomous-database-id $ADBocid|jq -r   '.data["lifecycle-state"]'`
echo "Current DB State is $status, sleeping for 10 seconds"
sleep 10
done
