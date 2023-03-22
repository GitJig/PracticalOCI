echo " This script must be executed from standby region "
echo " Use --region flag to switchover command if executing from primary region "
if [ -z "$1" -o  -z "$2" ]
then
    echo "Usage - switchover_adb.sh <INSERT_COMPARTMENT_NAME> <INSERT_DB_NAME>"
    exit;
fi
# Replace <INSERT_COMPARTMENT_NAME> with actual compartment name (case sensitive)
# Assumes unique compartment name in tenancy. Adjust for duplicate comparment names
export compname=$1
export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
# Replace <INSERT_DB_NAME> with actual DB name.
export DBname=$2

# Save DB OCID in variable based on name(case sensitive)
export ATPocid=`oci db autonomous-database list --compartment-id $Compocid --query "data[?contains(\"display-name\",'$DBname')]"|jq -r ".[].id"`
#This assumes only cross region DG setup.  To be adjusted for both local and cross region DG.
# Get DataGuard Peer OCID
export Peerdbocid=`oci db autonomous-database get --autonomous-database-id $ATPocid|jq -r '.data."peer-db-ids"[0]'`
#Get Peer Region from Peer OCID
export PeerRegion=`echo  $Peerdbocid|cut -d . -f 4`

#Switchover DB 
echo "Initiating Switchover - Status  update can take few minutes"
export WorkReqOCID=`oci db autonomous-database switchover --autonomous-database-id $ATPocid --peer-db-id $Peerdbocid |jq -r '."opc-work-request-id"'`

while true
do 
export status=`oci work-requests work-request get --work-request-id $WorkReqOCID|jq -r ".data.status"`
echo "Switchover request is $status"
echo "Ctrl-C to exit"
sleep 10
done

#check ADB DG recreation status
#This will only work if there is only 1 active DG recreation request. 
#Future Todo - Modify to exclude any old request
while true
do 
export percent_complete_status=`oci work-requests work-request list  --compartment-id $Compocid --resource-id $Peerdbocid --region $PeerRegion --query "data[?status!='SUCCEDED'&&\"operation-type\"=='Recreate Autonomous Data Guard standby']"|jq -r '.[]."percent-complete"'`
echo "Autonomous Data Guard Standby Recreation %  $percent_complete_status"
echo "Ctrl-C to exit"
sleep 10
done