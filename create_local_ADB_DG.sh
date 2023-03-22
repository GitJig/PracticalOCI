################
# This assumes unique compartment name in tenancy. 
# Adjust for duplicate compartments
if [ -z "$1" -o  -z "$2" ]
then
    echo "Usage - create_local_ADB_DG.sh <INSERT_COMPARTMENT_NAME> <INSERT_DB_NAME>"
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

export export WorkReqOCID=`oci db autonomous-database update --autonomous-database-id $ATPocid --is-local-data-guard-enabled true  |jq -r '."opc-work-request-id"'`
while true
do 
export status=`oci work-requests work-request get --work-request-id $WorkReqOCID|jq -r ".data.status"`
echo "Switchover request is $status"
echo "Ctrl-C to exit"
echo "Sleeping 20 seconds"
#exit the loop once switchover is completed
if [ $status == "SUCCEEDED" ]
then
    exit
fi
sleep 20
done
