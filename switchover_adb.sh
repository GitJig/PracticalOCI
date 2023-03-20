# This assumes unique compartment name in tenancy. 
# Adjust for duplicate compartments
# Replace <INSERT_COMPARTMENT_NAME> with actual compartment name
export compname=<INSERT_COMPARTMENT_NAME>
export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
# Replace <INSERT_DB_NAME> with actual DB name.
export DBname=<INSERT_DB_NAME>
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
