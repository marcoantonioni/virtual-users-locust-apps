# BAWVUT installable applications

This repository contains BAW applications used as examples for the BAWVUT tool.

Applications in .twx and .zip formats were created with BAW v23.x and are compatible with later versions.

## Installation example for runtime deployment in CP4BA Openshift runtime
This is a NON development runtime. 
The BAW runtime name is 'baw1'.
The namespace is 'cp4ba-baw-bai'
The deployment CR name is 'icp4adeploy'. 
```
TNS=cp4ba-baw-bai
BAW_NAME=baw1
CR_CP4BA=icp4adeploy
PAKADMIN_USER=cp4admin
PAKADMIN_PASSWORD=dem0s
APPLICATION=../zips/VirtualUsersSandbox-0.3.11.zip
./install-application.sh -n ${TNS} -b ${BAW_NAME} -c ${CR_CP4BA} -u ${PAKADMIN_USER} -p ${PAKADMIN_PASSWORD} -a ${APPLICATION}
```
