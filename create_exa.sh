export compname=$1
export Dispname=$2
export compcnt=$3
export strgcnt=$4

if [ $# -lt 4 ]
then
	echo "Usage: create_exa.sh <CompartmentName> <Displayname> <Compute Count> <Storage Count>=3 >"
	exit
fi
if [ $strgcnt -lt 3 ]
then
    echo " Storage count must be minimum 3"
    exit
elif [ $compcnt -lt 2 ]
then
    echo " Compute count must be minimum 2"
    exit
fi

export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`

if [ -z $Compocid ]
then
	echo "Compartment $compname not found"
	echo "Exiting"
	exit
fi

export ADname=`oci iam availability-domain  list --all --compartment-id $Compocid --raw-output --query 'data[0].name'`

oci db system-shape list --compartment-id $Compocid --output table --query 'data[?"shape-family"==`EXADATA`].{shapeFamily:"shape-family",shape:"shape"}'
echo "Enter Shape"
read shapename

if [ -z $shapename ]
then
	echo "Shape name is required"
	echo "Exiting"
	exit
fi 
echo "You have selected $shapename"
echo "Starting Exadata Infrastructure Creation"
export WorkReqOCID=`oci db cloud-exa-infra create --availability-domain $ADname --compartment-id $Compocid --display-name $Dispname --shape $shapename --compute-count $compcnt --storage-count $strgcnt|jq -r '."opc-work-request-id"'`
echo "Execute following command to check progress"
echo "oci work-requests work-request get --work-request-id $WorkReqOCID"
while true
do 
export status=`oci work-requests work-request get --work-request-id $WorkReqOCID|jq -r ".data.status"`
echo "Exadata Creation is $status"
echo "Ctrl-C to exit"
sleep 10
done
