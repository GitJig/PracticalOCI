export compname=$1
if [ -z $1 ]
then
	echo "Usage - getcompocid.sh <CompartmentName>"
	exit
fi

export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
if [ -z $Compocid ]
then
	echo "Compartment $compname not found"
        exit
fi
echo "OCID for compartment $compname is $Compocid"

