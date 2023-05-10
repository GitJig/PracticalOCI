export compname=$1
export Dispname=$2
export Updatecat=$3
export Newval=$4

if [ $# -ne 4 ]
then
	echo "Usage: update_exa_cluster.sh <CompartmentName> <Displayname> <CPU/Memory> <New Value>"
	exit
fi
export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
#List user specified Exa Infra Cluster

export ExaClusterocid=`oci db cloud-vm-cluster list --compartment-id $Compocid --display-name $Dispname --query 'data[0].id' --raw-output`
echo $ExaClusterocid
if [ -z $ExaClusterocid ] 
then
	echo "Cluster $Dispname not found in compartment $compname"
	echo "Exiting"
	exit
fi
if [ $Updatecat == "CPU" ]
then
    echo "Updating Cluster CPU"
    export WorkReqOCID=`oci db cloud-vm-cluster update --cloud-vm-cluster-id $ExaClusterocid --cpu-core-count $Newval |jq -r '."opc-work-request-id"'`
elif [ $Updatecat == "Memory" ]
then
    echo "Updating Cluster Memory"
    export WorkReqOCID=`oci db cloud-vm-cluster update --cloud-vm-cluster-id $ExaClusterocid --memory-size-in-gbs $Newval |jq -r '."opc-work-request-id"'`
fi

# Comment the below loop to exit the script immediately without waiting for work request to complete.
while true
do 
	export status=`oci work-requests work-request get --work-request-id $WorkReqOCID|jq -r ".data.status"`
	echo "Cluster update request is $status"
	echo "Ctrl-C to exit"
	echo "Sleeping 60 seconds"
	#exit the loop once update is completed
	if [ $status == "SUCCEEDED" ]
	then
		exit
	fi
	sleep 	60
done


