# This does not work with OCI CLI < 3.24.0  Do not use
echo " This script must be executed from Primary DB region "
if [ -z "$1" -o  -z "$2" -o -z "$3" ]
then
    echo "Usage - update_drtype_adb.sh <INSERT_COMPARTMENT_NAME> <INSERT_DB_NAME> <DRType>"
    echo "DRType must be ADG or BACKUP_BASED"
    exit;
fi

#VErify DRType value
if [ "$3" != "ADG" ] && [ "$3" != "BACKUP_BASED" ]
then    
    echo "Incorrect input for DRType. Enter ADG or BACKUP_BASED"
    exit;
fi

# Replace <INSERT_COMPARTMENT_NAME> with actual compartment name (case sensitive)
# Assumes unique compartment name in tenancy. Adjust for duplicate comparment names
export compname=$1
export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
# Replace <INSERT_DB_NAME> with actual DB name.
export DBname=$2
export DRtype=$3
# Save DB OCID in variable based on name(case sensitive)
export ATPocid=`oci db autonomous-database list --compartment-id $Compocid --query "data[?contains(\"display-name\",'$DBname')]"|jq -r ".[].id"`

if [ -z "$Compocid" -o  -z "$ATPocid" ]
then
    echo "Compartment - $compname or Autonomous DB - $DBname not found"
    echo "Exiting"
    exit;
fi

#Switchover DB 
echo "Initiating Switchover - Status  update can take few minutes"
export WorkReqOCID=`oci db autonomous-database change-disaster-recovery-configuration --autonomous-database-id $ATPocid --disaster-recovery-type $DRtype |jq -r '."opc-work-request-id"'`

# Loop to check switchover status. Exit loop when switchover is susccessful.

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
echo "Sleeping 60 seconds"
echo "Ctrl-C to exit"
sleep 60
done

