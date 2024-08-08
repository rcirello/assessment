#!/bin/bash
#Author: Renan Cirello
#E-mail: rcirello@gmail.com
#Purpose: Scripting Skills Assessment
#Script: System Patch Script

#.SYNOPSIS
#Patch OS with all available updates
  
#.DESCRIPTION
# - Check for pending reboots
# - Check for available updates
# - Generate a package list
# - Simulate the upgrade
# - Patch the system
# - Check for pending reboots
  
#.EXAMPLE
#system_patch.sh
  
#.NOTES

#Task: Create a script that performs the following operations:
#1. Checks for available system updates/patches.
#   apt-get -qq update
#2. Lists the updates/patches that are available.
#   apt list --upgradable
#3. Applies the updates/patches.
#   apt-get upgrade -y
#Logs the update process, including start time, end time, and the list of applied updates,
#to a file named patch_log.txt


#======== Configurations
SUPPORTED_OS_VERSIONS=("Ubuntu:20.04")                    #Comment this line to run the script withou OS Version limitations.
LOG_FILE_NAME='patch_log.txt'                                        #Log file
SCRIPT_NAME="${0}"

#======== Support Functions
if [ -f functions.sh ]; then
  source functions.sh
else
  echo "[ERROR] Missing function.sh file"
  exit 1
fi

#======== Script's own functions
fn_checkPendingReboot(){
  #.SYNOPSIS
  #Check for pending reboots
  
  #.DESCRIPTION
  #Check for pending reboots and end script execution if called with 'es' as 
  #parameter.
  
  #.EXAMPLE
  #fn_checkPendingReboot 'es'
  #fn_checkPendingReboot
  
  #.NOTES
  #General notes
  
  local l_endScript="${1}"
  local l_task="Check for Pending Reboot."
  fn_printTask "$RUNN" "$l_task"
  
  local l_pendingReboot="$(test -f /var/run/reboot-required; echo $?)"
  

  if [ "${l_endScript}" == 'es' ]; then                             #When match the es string, the function will throw an error
    if [ "${l_pendingReboot}" == '0' ]; then                                   #and finish the script execution.
      fn_execStatus 1 "$l_task" "A Pending Reboot was found, please reboot your system before continue."
    else
      fn_execStatus 0 "$l_task"
    fi
  else
    if [ "${l_pendingReboot}" == '0' ]; then
      fn_printMessage "$WARN" "A Pending Reboot was found in this computer, consider Reboot it as soon as possible."
    fi
  fi  
}

#======== Main
#Print "the script name" and a small description of its function.
echo -e "${B}System Patching Script${RST}"
echo -e "${C}Check, Update and Log system's patch data.${RST}"

fn_directoryHasPermissions "./"                                      #Check the current directory permissions, for log creation

fn_logMessage cl $INF "Starting log"                                 #Clean the content and start the log

fn_supportedOS                                                       #Check for supported OSs.

fn_forceRoot                                                         #Check for Administrator rights

fn_logMessage $INF "Starting System Patch"                           #Log patching operation start

fn_checkPendingReboot 'es'                                           #Check for pending reboots and end the script if there is one.

tmpFileUpgradeSimulation="$(mktemp)"
tmpFilePackageList="$(mktemp)"
tmpFileSystemUpgrade="$(mktemp)"

task="Check for available updates"                                   #Check for available updates
fn_printTask "${RUNN}" "${task}"
apt-get -qq update &
fn_waitProcess "${!}" "${RUNN}" "${task}"
fn_execStatus "${bgProcessExitCode}" "${task}"

task="Generte Package List."                                         #Generate a package list
fn_printTask "${RUNN}" "${task}"
apt list --upgradable 2> /dev/null >  "$tmpFilePackageList" &
fn_waitProcess "${!}" "${RUNN}" "${task}"
fn_execStatus "${bgProcessExitCode}" "${task}"

task="Log package list data."                                        #Log package list
fn_printTask "${RUNN}" "${task}"
cat "$tmpFilePackageList" | while read line; do fn_logMessage "${INF}" "$line"; done
fn_execStatus "${?}" "${task}"

task="Upgrade Simulation."                                           #Simulate the upgrade
fn_printTask "${RUNN}" "${task}"
apt-get -q --simulate upgrade 2>&1 > "$tmpFileUpgradeSimulation" &
fn_waitProcess "${!}" "${RUNN}" "${task}"
fn_execStatus "${bgProcessExitCode}" "${task}"

task="Log Simulation data."                                          #Log simulation
fn_printTask "${RUNN}" "${task}"
cat "$tmpFileUpgradeSimulation" | while read line; do fn_logMessage "${INF}" "$line"; done
fn_execStatus "${?}" "${task}"

echo -e "  $INF $(grep -iE '.*upgraded.*newly.*installed.*to remove and.*not upgraded..*' $tmpFileUpgradeSimulation)"

task="Upgrade system."                                               #Patch the system
fn_printTask "${RUNN}" "${task}"
apt-get upgrade -y 2> /dev/null > "$tmpFileSystemUpgrade" &
fn_waitProcess "${!}" "${RUNN}" "${task}"
fn_execStatus "${bgProcessExitCode}" "${task}"

task="Log Upgrade data."                                             #Log patch data
fn_printTask "${RUNN}" "${task}"
cat "$tmpFileSystemUpgrade" | while read line; do fn_logMessage "${INF}" "$line"; done
fn_execStatus "${?}" "${task}"

fn_checkPendingReboot                                                #Check for pending reboots and warn the user about it.
                                                                     #Inform the user the log location
fn_printMessage "$INF" "Log information can be found at $LOG_FILE_NAME file."

rm -f "$tmpFileUpgradeSimulation" "$tmpFilePackageList" "$tmpFilePackageList"

fn_logMessage "$INF" "System Patch Ended"                            #Log patching operation end