#!/bin/bash

#-----------------------------------------------
# ./install-application.sh -n cp4ba-wfps-baw-pfs -b baw1 -c icp4deploy -u cp4admin -p dem0s -a VirtualUsersSandbox-0.3.7.zip

_CLR_OFF="\033[0m"     # Color off
_CLR_BLNK="\033[5m"    # Blink
_CLR_BLU="\033[0;34m"  # Blue
_CLR_CYN="\033[0;36m"  # Cyan
_CLR_GRN="\033[0;32m"  # Green
_CLR_PPL="\033[0;35m"  # Purple
_CLR_RED="\033[0;31m"  # Red
_CLR_WHT="\033[0;37m"  # White
_CLR_YLW="\033[0;33m"  # Yellow
_CLR_BBLU="\033[1;34m" # Bold Blue
_CLR_BCYN="\033[1;36m" # Bold Cyan
_CLR_BGRN="\033[1;32m" # Bold Green
_CLR_BPPL="\033[1;35m" # Bold Purple
_CLR_BRED="\033[1;31m" # Bold Red
_CLR_BWHT="\033[1;37m" # Bold White
_CLR_BYLW="\033[1;33m" # Bold Yellow

_BAW_DEPL_NAMESPACE=""
_BAW_DEPL_NAME=""
_CR_NAME=""
_BAW_ADMINUSER=""
_BAW_ADMINPASSWORD=""
_BAW_BAW_APP_FILE=""
_BAW_BAW_APP_CASE_FORCE=false
_BAW_DESIGN_OS=""
_BAW_TARGET_ENV=""
_IS_CASE_SOL=false

usage () {
  echo ""
  echo -e "${_CLR_GREEN}usage: $_me
    -n namespace
    -b baw-name
    -c cr-name 
    -u admin-user
    -p password
    -a app-file
    -d design-object-store
    -e target-environment
    -f force-case${_CLR_NC}"
}


#--------------------------------------------------------
# read command line params
while getopts n:b:c:u:p:a:d:e:f flag
do
    case "${flag}" in
        n) _BAW_DEPL_NAMESPACE=${OPTARG};;
        b) _BAW_DEPL_NAME=${OPTARG};;
        c) _CR_NAME=${OPTARG};;
        u) _BAW_ADMINUSER=${OPTARG};;
        p) _BAW_ADMINPASSWORD=${OPTARG};;
        a) _BAW_BAW_APP_FILE=${OPTARG};;
        f) _BAW_BAW_APP_CASE_FORCE=true;;
        d) _BAW_DESIGN_OS=${OPTARG};;
        e) _BAW_TARGET_ENV=${OPTARG};;
    esac
done

installApplication () {

  echo "Installing application file: ${_BAW_BAW_APP_FILE}"
  _BAW_EXTERNAL_BASE_URL=$(oc get ICP4ACluster -n ${_BAW_DEPL_NAMESPACE} ${_CR_NAME} -o jsonpath='{.status.endpoints}' | jq '.[] | select(.scope == "External") | select(.name | contains("base URL for '${_BAW_DEPL_NAME}'"))' | jq .uri | sed 's/"//g')

  if [[ -z "${_BAW_EXTERNAL_BASE_URL}" ]]; then
    echo "External base URL not found, please login to OCP cluster or verify the parameters"
    exit 1
  fi

  LOGIN_URI="${_BAW_EXTERNAL_BASE_URL}ops/system/login"

  echo "Wait for CSRF token, login to ${LOGIN_URI}"
  until _CSRF_TOKEN=$(curl -ks -u ${_BAW_ADMINUSER}:${_BAW_ADMINPASSWORD} -X POST -H 'accept: application/json' -H 'Content-Type: application/json' ${LOGIN_URI} -d '{"refresh_groups": true, "requested_lifetime": 7200}' | jq .csrf_token 2>/dev/null | sed 's/"//g') && [[ -n "$_CSRF_TOKEN" ]]
  do
    echo -n "."
    sleep 1
  done

  echo ""
  _CASE_ATTRS=""
  if [[ "${_IS_CASE_SOL}" = "true" ]]; then
    _CASE_ATTRS="&caseDosName=${_BAW_DESIGN_OS}&caseProjectArea=${_BAW_TARGET_ENV}"
    echo "Deploying case solution application"
  else
    echo "Deploying workflow application"
  fi


  _INSTALL_CMD="ops/std/bpm/containers/install?inactive=false%26caseOverwrite=${_BAW_BAW_APP_CASE_FORCE}${_CASE_ATTRS}"
  INST_RESPONSE=$(curl -sk -u ${_BAW_ADMINUSER}:${_BAW_ADMINPASSWORD} -H 'accept: application/json' -H 'BPMCSRFToken: '${_CSRF_TOKEN} -H 'Content-Type: multipart/form-data' -F 'install_file=@'${_BAW_BAW_APP_FILE}';type=application/x-zip-compressed' -X POST "${_BAW_EXTERNAL_BASE_URL}${_INSTALL_CMD}")
  INST_DESCR=$(echo ${INST_RESPONSE} | jq .description 2>/dev/null | sed 's/"//g')
  INST_URL=$(echo ${INST_RESPONSE} | jq .url 2>/dev/null | sed 's/"//g')

  echo "Request result: "${INST_DESCR}
  sleep 2
  echo "Get installation status at url: ${INST_URL}"
  if [[ ! -z "${INST_URL}" ]]; then
    while [ true ]
    do
      INST_STATE=$(curl -sk -u ${_BAW_ADMINUSER}:${_BAW_ADMINPASSWORD} -H 'accept: application/json' -H 'BPMCSRFToken: '${_CSRF_TOKEN} -X GET ${INST_URL} | jq .state | sed 's/"//g')
      if [[ ${INST_STATE} == "running" ]]; then
        sleep 2
      else
        echo ""
        echo "Final installation state: "${INST_STATE}
        break
      fi
    done
  else
    echo "ERROR during installation ${INST_DESCR}"
  fi
}

if [[ ! -z "${_BAW_DESIGN_OS}" ]] || [[ ! -z "${_BAW_TARGET_ENV}" ]]; then
  _IS_CASE_SOL=true
fi
if [[ "${_IS_CASE_SOL}" = "true" ]]; then
  if [[ -z "${_BAW_DESIGN_OS}" ]] || [[ -z "${_BAW_TARGET_ENV}" ]]; then 
    # force error
    _BAW_DEPL_NAMESPACE=""
  fi
fi
if [[ -z "${_BAW_DEPL_NAMESPACE}" ]] || [[ -z "${_BAW_DEPL_NAME}" ]] || [[ -z "${_CR_NAME}" ]] || 
   [[ -z "${_BAW_ADMINUSER}" ]] || [[ -z "${_BAW_ADMINPASSWORD}" ]] || [[ -z "${_BAW_BAW_APP_FILE}" ]]; then
  echo "ERROR: Empty values for required parameter"
  usage
  exit 1
fi
if [[ ! -f "${_BAW_BAW_APP_FILE}" ]]; then
  echo "Application file not found: "${_BAW_BAW_APP_FILE}
  exit 1
fi

installApplication
