# Install application

TNS=cp4ba-baw-bai
BAW_NAME=baw1
CR_CP4BA=icp4adeploy
PAKADMIN_USER=cp4admin
PAKADMIN_PASSWORD=dem0s
APPLICATION=../zips/VirtualUsersSandbox-0.3.11.zip
./install-application.sh -n ${TNS} -b ${BAW_NAME} -c ${CR_CP4BA} -u ${PAKADMIN_USER} -p ${PAKADMIN_PASSWORD} -a ${APPLICATION}
