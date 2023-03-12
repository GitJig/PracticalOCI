 #Tested with OCI Cloud Shell
 #This will display status of workrequest specified by WorkReqOCID variable
 export WorkReqOCID=<REPLACE_WORKREQUESTOCID_HERE>
 if [ -z $1 ]
 then
 oci work-requests work-request get --work-request-id $WorkReqOCID
 else
 oci work-requests work-request get --work-request-id $1
 fi
