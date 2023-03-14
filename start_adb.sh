# Replace <INSERT_COMPARTMENT_NAME> with actual compartment name (case sensitive)
export compname=<INSERT_COMPARTMENT_NAME>
export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
# Replace <INSERT_DB_NAME> with actual DB name.
export DBname=<INSERT_DATABASE_NAME>
# Save DB OCID in variable based on DB name(case sensitive)
export ATPocid=`oci db autonomous-database list --compartment-id $Compocid --query "data[?contains(\"display-name\",'$DBname')]"|jq -r ".[].id"`
export WorkReqOCID=`oci db autonomous-database start --autonomous-database-id $ATPocid |jq -r '."opc-work-request-id"'`
while true
do 
export status=`oci work-requests work-request get --work-request-id $WorkReqOCID|jq -r ".data.status"`
echo "startup status -- $status"
echo "Ctrl-C to exit"
sleep 10
done
