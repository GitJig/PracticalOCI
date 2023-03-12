#Script to stop/start ADB
export compname=<INSERT_COMPARTMENT_NAME>
export comp_id=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
#save OCID in variable based on name(case sensitive) string
export DBname=<INSERT_DB_NAME>
export ATPocid=`oci db autonomous-database list --compartment-id $comp_id --query "data[?contains(\"display-name\",'$DBname')]"|jq -r ".[].id"`
#stop ADB Uncomment next 2 lines to stop ADB
#export WorkReqOCID=`oci db autonomous-database stop --autonomous-database-id  $ATPocid|jq -r '."opc-work-request-id"'`
#oci work-requests work-request get --work-request-id $WorkReqOCID

#Start ADB. Uncomment next line to start DB
#oci db autonomous-database start --autonomous-database-id  $ATPocid
