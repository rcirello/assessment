#!/bin/bash
#Author: Renan Cirello
#E-mail: rcirello@gmail.com
#Purpose: Scripting Skills Assessment
#Script: Functions

#== Terminal Colors
G="\033[0;32m"
O="\033[0;33m"
R="\033[0;31m"
W="\033[1;37m"
Y="\033[1;33m"
B="\033[0;34m"
C="\033[0;36m"
RST="\033[0m"

#== Status Messages
OK="${G}[SUCCESS]${RST}"
KO="${R}[FAILED]${RST}"
INF="${W}[INFO]${RST}"
ERR="${R}[ERROR]${RST}"
WARN="${O}[WARNING]${RST}"
RUNN="${O}[RUNNING]${RST}"
SKIP="${C}[SKIPPED]${RST}"

#== Tasks
#Variables used to give a more homogeneous visual when printing information on
TASK_STRING_SIZE=30 #The screen
LOG_STRING_SIZE=10  #The log
#Chars that compose the load string, used to give some idea of progress when 
#executing long tasks
LOAD_STRING[0]="-"  
LOAD_STRING[1]="\\"
LOAD_STRING[2]="|"
LOAD_STRING[3]="/"
export LOAD_STRING

#== Support Functions
fn_execStatus(){
  #.SYNOPSIS
  #Function to help check the exit code from command execution and manage 
  #tasks status
  
  #.DESCRIPTION
  #Receive a exit code ($?) or a boolean (0/1) to return the related 
  #string (Succes/Failed) and a custom error message for that task.
  #The custom error message is a optional paramenter.
  #The script execution is ended if an error state is passed.
  
  #.EXAMPLE
  #fn_execStatus $? "<Task String>" "<Error Message String>"
  #fn_execStatus 0 "<Task String>" 
  #fn_execStatus 1 "<Task String>" "<Error Message String>"
  
  #.NOTES
    
  local l_exitStatus="${1}"
  local l_msgString="${2}"
  local l_msgStringErr="${3}"

  if [ "${l_exitStatus}" == '0' ]; then
    fn_printTask nl "${OK}" "${l_msgString}" 
  else
    fn_printTask nl "${KO}" "${l_msgString}" 
    if [ ! -z "${l_msgStringErr}" ] && [ ! "${l_msgStringErr}" == "" ]; then
      fn_printMessage "$ERR" "${l_msgStringErr}"
    fi
    exit 1
  fi
}

fn_printTask(){
  #.SYNOPSIS
  #Function to help inform the steps executed by the script to the user..

  #.DESCRIPTION
  #This function was made to inform the user about what is being executed by the
  #scritpt.
  #It allows rewriting task lines giving "a dynamic sense" that the 
  #steps are running, and the opportunity to keep only final status
  #on the screen.
  #It also call the fn_logMessage function to allow log operations,
  #the string sl can be used when calling it to skip log operations.

  
  #.EXAMPLE
  #Print a task an move to the next line
  #fn_printTask nl "<Status String>" "<Message String>"

  #Print a task but keep the cursor at the same line, allowing to rewrit that line.
  #fn_printTask "<Status String>" "<Message String>"

  #Skip log
  #fn_printTask sl "<Status String>" "<Message String>"

  #Skip log and move to the next line, the order is important
  #fn_printTask sl nl "<Status String>" "<Message String>"
  
  #.NOTES

  local l_skipLog='0'

  if [ "${1}" == 'nl' ]; then                                        #Check whether to move to next line or not
    local l_echoOpts='-e'
    shift 1
  else
    local l_echoOpts='-ne'
  fi

  if [ "${1}" == 'sl' ]; then                                        #Check whether to skip log or not
    l_skipLog='1'
    shift 1
  fi 

  local l_statusString="${1}"
  local l_msgString="${2}"
                                                                     #Get the size of the status string to manipulate the log output.
  local l_statusSize=$(echo -ne "${l_statusString}" | wc -c)         #The idea is to give homogeneous view of the script output.
  local l_fillingChars=$(awk "BEGIN{ for(c=0;c<$((${TASK_STRING_SIZE}-${l_statusSize}));c++) printf \"-\"}")
  
  echo ${l_echoOpts} "* ${l_statusString} ${l_fillingChars}-> ${l_msgString}\033[0K\r"
  
  if [ "${l_skipLog}" == '0' ]; then 
    fn_logMessage "${l_statusString}" "${l_msgString}"               #Call the fn_logMessage to log the operation
  fi
  
}

fn_waitProcess(){
  #.SYNOPSIS
  # Wait for a process while executed in background.

  #.DESCRIPTION
  #Receive the PID and task information to provide a dynamic task 
  #line, giving the user te sensation that the operation is running
    
  #.EXAMPLE
  #fn_waitProcess "<PID>" "<Status String>" "<Message String>"
  #fn_waitProcess "${!}" "${RUNN}" "${task}"
  
  #.NOTES
  local l_processPid="${1}"
  local l_statusString="${2}"
  local l_msgString="${3}"
  bgProcessExitCode=""
 
  while true
  do 
    for string in "${LOAD_STRING[@]}"
    do
      fn_printTask 'sl' "${l_statusString} $string" "${l_msgString}"
      sleep 0.5
    done
    if [ ! -d "/proc/${l_processPid}" ]; then
      wait ${l_processPid}
      bgProcessExitCode="${?}"
      break
    fi    
  done
}

function fn_printMessage(){
  #.SYNOPSIS
  #Print a message to the user.
  
  #.DESCRIPTION
  #Print a message to the user and call the fn_logMessage to log it.
  
  #.EXAMPLE
  #fn_printMessage "<Status String>" "<Message String>"
  
  #.NOTES
  local l_statusString="${1}"
  local l_msgString="${2}"
  
  echo -e "  ${l_statusString}" "${l_msgString}"
  fn_logMessage "${l_statusString}" "${l_msgString}"
  
}

fn_supportedOS(){
  #.SYNOPSIS
  #Ensure the script will only run under tested/supported Operating Systems.
  
  #.DESCRIPTION
  #This function is based on the definition of the $SUPPORTED_OS_VERSIONS var,
  #an array which contains strings that could be matched with the 
  #$ID:$VERSION_ID string, sourced from the /etc/os-release file
  #If the OS is not supported the user receive an error and a list of
  #supported OSs.
  #If the $SUPPORTED_OS_VERSIONS is not defined, the function will not be
  #executed.
  
  #.EXAMPLE
  #fn_supportedOS 
  
  #.NOTES

  local l_task='Check OS support.'
  fn_printTask "${RUNN}" "${l_task}"

  if [ ! -z ${SUPPORTED_OS_VERSIONS} ]; then                         #Check if there $SUPPORTED_OS_VERSIONS is defined.
    source /etc/os-release                                           #Source os-release file
    if ! $(echo ${SUPPORTED_OS_VERSIONS} | grep -qi "${ID}:${VERSION_ID}") ; then  #Check if teh OS is supported
      local l_supportedOSList="$(echo ${SUPPORTED_OS_VERSIONS} | sed 's/,/\//g' )" #When not supported, the user receive a list of the defined supported OSs.
      fn_execStatus '1' "$l_task" "This script only support the following OSs: ${l_supportedOSList}"
      exit 1
    else
      fn_execStatus '0' "$l_task"
    fi
  fi
}

fn_forceRoot(){
  #.SYNOPSIS
  #Ensure the script is running under the root privileges.
  
  #.DESCRIPTION
  #This function use is being executed under root privileges.
  
  #.EXAMPLE
  #fn_forceRoot
  
  #.NOTES

  local l_task="Check Administrative rights."
  fn_printTask "${RUNN}" "${l_task}"

  if [ $(whoami) != 'root' ]; then
    fn_execStatus 1 "$l_task" "This script must be executed with root rights."
    exit 1
  else
    fn_execStatus 0 "$l_task"
  fi
}

fn_directoryHasPermissions(){
  #.SYNOPSIS
  #Ensure a given directory has enough permissions.
  
  #.DESCRIPTION
  #This function uses the ownership data from the file to check
  #if the user have enough permissions to read the files from 
  #the given directory and to write the report at the end.
  #If not, the script inform the user which permissions are needed.
  #
    
  #.EXAMPLE
  #fn_directoryHasPermissions "<directory>"
  
  #.NOTES
  local l_path="${1}"
  local l_task="Check path permissions."
  local l_permErrorMsg=""
  local l_reportFullPath=""
  fn_printTask "${RUNN}" "${l_task}"

  if [ ! -r "${l_path}" ]; then                                      #Check user permissions
    l_permErrorMsg=read  

    elif [ ! -w "${l_path}" ]; then
      l_permErrorMsg=write

      elif [ ! -x "${l_path}" ]; then
        l_permErrorMsg=access
  fi

  if [ -z ${l_permErrorMsg} ]; then                                  #Check if some permission is missing
    fn_execStatus 0 "${l_task}"
  else
    local l_currUserName="$(whoami)"                                 #If some permission is missing, the script compose a message to the user
    local l_currUserGroups="$(groups ${user_name})"                  #informing the permissions needed.
    local l_directoryOwner=$(stat -c %U "${directory_path}")
    local l_directoryGroupOwner=$(stat -c %G "${directory_path}")
    local l_userOwnershipType=""
    
    if [ "${l_currUserName}" == "${l_directoryOwner}" ]; then
      l_userOwnershipType='u'

      elif echo "${l_currUserGroups}" | grep -q "${l_directoryOwner}"; then
        l_userOwnershipType='g'

      else
        l_userOwnershipType='o'
    fi
         
    fn_execStatus 1 "${l_task}" "The current user ${O}(${l_currUserName}) don't have ${l_permErrorMsg} permissions${RST} in the provided path (${W}${l_path}${RST})\n  $INF ${O}Ensure ${O}${l_userOwnershipType}=rwx permissions${RST}, or ask your System Administrator to review path's permisions/ownership."
    exit 1
  fi
}

fn_isDirectory(){
  #.SYNOPSIS
  #Check if a given path is a directory or not
  
  #.DESCRIPTION
  #For this context, this function check if the given path is a 
  #directory, throwing an error and ending the script if it is not.
    
  #.EXAMPLE
  #fn_isDirectory "<path>"

  #.NOTES

local l_task="Check if the path is a directory."
local l_path="${1}"

fn_printTask "${RUNN}" "${l_task}"

if [ ! -d "${l_path}" ]; then
  fn_execStatus 1 "${l_task}" "The provided path is not a directory (${W}${l_path}${RST})"
  exit 1
else
  fn_execStatus 0 "${l_task}"  
fi
}

fn_logMessage(){
  #.SYNOPSIS
  #Allow to log script operations into a pre-defined log file.
  
  #.DESCRIPTION
  #This function is based on the definition of the $LOG_FILE_NAME var,
  #a simple string containing the file in which the operations should be
  #logged into.
  #If the variable $SCRIPT_NAME is also defined, the function log the messages
  #containing also the script name.
  
  #If the $LOG_FILE_NAME is not defined, the function will not be
  #executed.
  
  #The function can clean the file content and add a log message or simply add
  #the log message
  
    
  #.EXAMPLE
  #Clean the log file content and log a message
  #fn_logMessage cl "<status string>" "<message string>" 

  #Log a message
  #fn_logMessage cl "<status string>" "<message string>" 

  #.NOTES
  #Possible Log Formats:
  #[Date/Time] [Script Name] [Status] [Log message]
  #[Date/Time] [Status] [Log message]
  
                                                                     #Check if $LOG_FILE_NAME is defined.
  if [ ! -z "${LOG_FILE_NAME}" ] && [ ! "${LOG_FILE_NAME}" == "" ]; then
    if [ "${1}" == 'cl' ]; then                                      #Check if the first argument is the 'cl' string.
      > $LOG_FILE_NAME                                               #When True, the function clean the file content.
      shift 1
    fi

    local l_statusString="$(echo ${1} | sed 's/.*\(\[.*\]\).*/\1/g')"
    local l_msgString="${2}"
                                                                     #Get the size of the status string to manipulate the log output.
    local l_statusSize=$(echo -ne "${l_statusString}" | wc -c)       #The idea is to give a "field aspect" to the log files, making it easy to read. 
    local l_fillingChars=$(awk "BEGIN{ for(c=0;c<$((${LOG_STRING_SIZE}-${l_statusSize}));c++) printf \" \"}")            
    
    
    if [ ! -z "${SCRIPT_NAME}" ] && [ ! "${SCRIPT_NAME}" == "" ]; then 
      local l_script_name="[$SCRIPT_NAME] "                          #Check if $SCRIPT_NAME is defined, to add or not the script on the log lines.
    fi
    
    echo "[$(date -R)] ${l_script_name}${l_statusString}${l_fillingChars}${l_msgString}" >> $LOG_FILE_NAME
  fi
}