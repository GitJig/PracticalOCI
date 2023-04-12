# Assumes unique compartment name in tenancy. Adjust for duplicate compartment names
if [ $# -lt 2 ]
then
	echo "Usage: stop_adb.sh <Compartment Name> <DatabaseName>"
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


export ATPocid=`oci db autonomous-database list --compartment-id $Compocid --query "data[?contains(\"display-name\",'$DBname')]"|jq -r ".[].id"`

if [ -z $ATPocid ]
then
	echo "Database $DBname not found"
	echo "Exiting"
	exit
fi

# Save DB OCID in variable based on DB name(case sensitive)
export ATPocid=`oci db autonomous-database list --compartment-id $Compocid --query "data[?contains(\"display-name\",'$DBname')]"|jq -r ".[].id"`
export WorkReqOCID=`oci db autonomous-database stop --autonomous-database-id $ATPocid |jq -r '."opc-work-request-id"'`
while true
do 
export status=`oci work-requests work-request get --work-request-id $WorkReqOCID|jq -r ".data.status"`
echo "DB stop is $status"
echo "Ctrl-C to exit"
sleep 30
done
