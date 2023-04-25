# Replace <INSERT_COMPARTMENT_NAME> with actual compartment name
if [ $# -ne 3 ]
then 
    echo "Usage: scale_adb.sh <CompartmentName> <DB Name> <New CPU Count>"
    echo "Exiting"
    exit
fi

export compname=$1
export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`

if [ -z $Compocid ]
then
    echo "Compartment $compname not found"
    echo "Exiting"
    exit
fi

export DBname=$2
# Save DB OCID in variable based on name(case sensitive)
export ATPocid=`oci db autonomous-database list --compartment-id $Compocid --query "data[?contains(\"display-name\",'$DBname')]"|jq -r ".[].id"`

if [ -z $ATPocid ]
then
    echo "Database $DBName not found"
    echo "Exiting"
    exit
fi

export Compcnt=$3
# compute-count must be in multiples of 2 for ECPU model and the value must be different from current CPU allocation.  
export WorkReqOCID=`oci db autonomous-database update --compute-count $Compcnt --autonomous-database-id $ATPocid|jq -r '."opc-work-request-id"'`

while true
do 
    export status=`oci work-requests work-request get --work-request-id $WorkReqOCID|jq -r ".data.status"`
    echo "Scaling request $status"
    echo "Sleeping 30 Seconds"
    echo "Ctrl-C to exit"

    if [ $status == "SUCCEEDED" ]
    then
        exit
    fi

sleep 30
done
