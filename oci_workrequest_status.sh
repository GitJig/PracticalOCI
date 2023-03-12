 #Tested in OCI Cloud Shell
 #This will display status of workrequest specified by WorkReqOCID variable
 export WorkReqOCID=<REPLACE_WORKREQUESTOCID_HERE>
 oci work-requests work-request get --work-request-id $WorkReqOCID
