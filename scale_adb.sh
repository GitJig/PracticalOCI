# Replace <INSERT_COMPARTMENT_NAME> with actual compartment name
export compname=<INSERT_COMPARTMENT_NAME>
export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
# Replace <INSERT_DB_NAME> with actual DB name.
export DBname=<INSERT_DB_NAME>
# Save DB OCID in variable based on name(case sensitive)
export ATPocid=`oci db autonomous-database list --compartment-id $Compocid --query "data[?contains(\"display-name\",'$DBname')]"|jq -r ".[].id"`
# compute-count must be in multiples of 2 for ECPU model and the value must be different from current CPU allocation.  
export WorkReqOCID=`oci db autonomous-database update --compute-count 2 --autonomous-database-id $ATPocid|jq -r '."opc-work-request-id"'`
while true
do 
export status=`oci work-requests work-request get --work-request-id $WorkReqOCID|jq -r ".data.status"`
echo "Scaling request $status"
echo "Ctrl-C to exit"
sleep 10
done
