export Clusterdispname=$1
export ClusterName=$2
export CPUcount=$3
export Hostname=$4
export KeyPath=$5
export GIVer=$6
export DataStorageTB=$7
export MemGB=$8
export Listport=$9
export Compname=poc-cmp

#Set timezone for Singapore. Change as required.
export Timezone="Asia/Singapore"
if [ $# -ne 9 ]
then
    echo "Usage: create_exa_cluster.sh <Displayname> <Clustername> <CPUCount> <HostnamePrefix> <Path to public key file> <GIVersion(19.0.0.0)> <storage TB> <memory GB> <ListenerPort> "
    exit
fi

#List available Exa Infra
export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${Compname}\") | .id"`
oci db cloud-exa-infra list --compartment-id $Compocid --query 'data[].{Displayname:"display-name",NumDBServers:"compute-count",StorageNode:"activated-storage-count",InfraStatus:"lifecycle-state"}' --output table

echo "Enter Infrastructure Name for Cluster Creation"
read exainfraname

if [ -z $exainfraname ]
then
    echo "Infrastructure name is required"
    echo "Exiting"
    exit
fi

export Exainfraocid=`oci db cloud-exa-infra list --compartment-id $Compocid --all --query "data[?contains(\"display-name\",'$exainfraname')].id"|jq -r '.[]'`
echo $Exainfraocid

if [ -z $Exainfraocid ]
then
    echo "Exa Infrastructure $exainfraname not found"
    echo "Exiting"
    exit
fi


oci network vcn list --compartment-id $Compocid --query 'data[].{Displayname:"display-name",CIDRBlock:"cidr-block"}' --output table
echo "Enter VCN Name for Cloud Exadata Cluster creation"
read vcnname

if [ -z $vcnname ]
then
    echo "Infrastructure name is required"
    echo "Exiting"
    exit
fi

export Vcnocid=`oci network vcn list --compartment-id $Compocid --all --query "data[?contains(\"display-name\",'$vcnname')].id"|jq -r '.[]'`
echo $Vcnocid

oci network subnet list --compartment-id $Compocid --all |jq -r '.data[] | select (."vcn-id"=='\"$Vcnocid\"') | "SubnetName"+"  "+."display-name"+"----CIDR----"+."cidr-block" '

echo "Select Client Subnet"
read ClientSub

oci network subnet list --compartment-id $Compocid --all |jq -r '.data[] | select (."vcn-id"=='\"$Vcnocid\"') | "SubnetName"+"  "+."display-name"+"----CIDR----"+."cidr-block" '

export ClientSubOCID=`oci network subnet list --compartment-id $Compocid --all --query "data[?contains(\"display-name\",'$ClientSub')].id"|jq -r '.[]'`
echo $ClientSubOCID

echo "Select Backup Subnet"
read BackupSub

export BackupSubOCID=`oci network subnet list --compartment-id $Compocid --all --query "data[?contains(\"display-name\",'$BackupSub')].id"|jq -r '.[]'`
echo $BackupSubOCID


oci db cloud-vm-cluster create --cloud-exa-infra-id $Exainfraocid --compartment-id $Compocid --display-name $Clusterdispname --cluster-name $ClusterName --backup-subnet-id $BackupSubOCID --subnet-id $ClientSubOCID --cpu-core-count $CPUcount --gi-version $GIVer --hostname $Hostname --ssh-authorized-keys-file $KeyPath --scan-listener-port-tcp $Listport --data-storage-size-in-tbs $DataStorageTB --memory-size-in-gbs $MemGB --time-zone $Timezone --db-servers file:///home/jigar_dosh/dbservers.json --db-node-storage-size-in-gbs 500
