echo " This script must be executed from standby region if using OCI Cloud Shell"
echo " Use --region flag to switchover command if executing from primary region OCI Cloud Shell"
if [ -z "$1" -o  -z "$2" ]
then
    echo "Usage - switchover_adb.sh <INSERT_COMPARTMENT_NAME> <INSERT_DB_NAME>"
    exit;
fi
# Replace <INSERT_COMPARTMENT_NAME> with actual compartment name (case sensitive)
# Assumes unique compartment name in tenancy. Adjust for duplicate comparment names
export compname=$1
export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
# Replace <INSERT_DB_NAME> with actual DB name.
export DBname=$2

# Save DB OCID in variable based on name(case sensitive)
export ATPocid=`oci db autonomous-database list --compartment-id $Compocid --query "data[?contains(\"display-name\",'$DBname')]"|jq -r ".[].id"`
#This assumes only cross region DG setup.  To be adjusted for both local and cross region DG.
# Get DataGuard Peer OCID
export Peerdbocid=`oci db autonomous-database get --autonomous-database-id $ATPocid|jq -r '.data."peer-db-ids"[0]'`
#Switchover DB 

export WorkReqOCID=`oci db autonomous-database switchover --autonomous-database-id $ATPocid --peer-db-id $Peerdbocid |jq -r '."opc-work-request-id"'`

while true
do 
export status=`oci work-requests work-request get --work-request-id $WorkReqOCID|jq -r ".data.status"`
echo "Switchover request is $status"
echo "Ctrl-C to exit"
sleep 10
done

#check ADB DG recreation status
while true
do 
export status=`oci work-requests work-request list  --compartment-id $Compocid --resource-id $ATPocid --query "data[?status=='ACCEPTED'&&\"operation-type\"=='Recreate Autonomous Data Guard standby']"|jq -r ".[].id"`
echo "Autonomous Data Guard Standby is $status"
echo "Ctrl-C to exit"
sleep 10
done