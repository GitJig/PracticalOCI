# Replace <INSERT_COMPARTMENT_NAME> with actual compartment name
export compname=<INSERT_COMPARTMENT_NAME>
export Compocid=`oci iam compartment list --compartment-id-in-subtree true --all |jq -r ".data[] | select(.name == \"${compname}\") | .id"`
# Replace <INSERT_DB_NAME> with actual DB name.
export DBname=<INSERT_DB_NAME>

# Save DB OCID in variable based on name(case sensitive)
export ATPocid=`oci db autonomous-database list --compartment-id $Compocid --query "data[?contains(\"display-name\",'$DBname')]"|jq -r ".[].id"`
export bucketname=Wallet_$DBname

#get namespace 
export namespace=`oci os ns get|jq -r ".data"`

# use [] to filter {} from jq output and extract only connection strings
echo "=============== EZConnect connection strings =================================" > ConnectionStrings_$DBname.txt
oci db autonomous-database get --autonomous-database-id $ATPocid |jq -r '.data."connection-strings"."all-connection-strings"[]' >> ConnectionStrings_$DBname.txt

echo "=============================================================================" >> ConnectionStrings_$DBname.txt
echo "=============== TLS Long form connection strings =================================" >> ConnectionStrings_$DBname.txt
oci db autonomous-database get --autonomous-database-id $ATPocid |jq -r '.data."connection-strings".profiles[].value'|grep 1521 >> ConnectionStrings_$DBname.txt
echo "=============================================================================" >> ConnectionStrings_$DBname.txt
echo "=============== MTLS Long form connection strings =================================" >> ConnectionStrings_$DBname.txt
oci db autonomous-database get --autonomous-database-id $ATPocid |jq -r '.data."connection-strings".profiles[].value'|grep 1522 >> ConnectionStrings_$DBname.txt
echo "=============================================================================" >> ConnectionStrings_$DBname.txt

#Upload connection strings to bucket.  Use --force to overwrite existing file
oci os object put -bn $bucketname --file ConnectionStrings_$DBname.txt -ns $namespace --force
