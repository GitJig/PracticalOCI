echo " This script must be executed from Primary DB region "
if [ -z "$1" -o  -z "$2" ]
then
    echo "Usage - switchover_local_adb.sh <INSERT_COMPARTMENT_NAME> <INSERT_DB_NAME>"
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

#Switchover DB 
echo "Initiating Switchover - Status  update can take few minutes"
export WorkReqOCID=`oci db autonomous-database switchover --autonomous-database-id $ATPocid |jq -r '."opc-work-request-id"'`

# Loop to check switchover status. Exit loop when switchover is successful.

while true
do 
export status=`oci work-requests work-request get --work-request-id $WorkReqOCID|jq -r ".data.status"`
echo "Switchover request is $status"
#exit the loop once switchover is completed
if [ $status == "SUCCEEDED" ]
then
    echo "Switchover Succeeded for $DBname"
    break
fi
echo "Sleeping 20 seconds"
echo "Ctrl-C to exit"
sleep 20
done

