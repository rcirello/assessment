#!/bin/bash
#Author: Renan Cirello
#E-mail: rcirello@gmail.com
#Purpose: Scripting Skills Assessment
#Script: Reset Administrator password and disable the account

#.SYNOPSIS
#Reset root password and disable the account.
  
#.DESCRIPTION
# - Generate a random password, which is informed to the user, but not logged
# - Change root password.
# - Lock root password.
# - If openssh-server is installed
# - Block root login from SSH
# - Reload SSH service.
  
#.EXAMPLE
#reset_disable_root_account.sh
  
#.NOTES
#This script will not change root user shell configration, third 
#party scripts could make use of root's shell to execute operations.
#The usage of nologin shell can generate future problemas, so the
#account's password and SSH access will be blocked.


#======== Configurations
SUPPORTED_OS_VERSIONS=("Ubuntu:20.04")                    #Comment this line to run the script withou OS Version limitations.
LOG_FILE_NAME='account_management_log.txt'                           #Log file
SCRIPT_NAME="${0}"

#======== Support Functions
if [ -f functions.sh ]; then
  source functions.sh
else
  echo "[ERROR] Missing function.sh file"
  exit 1
fi

#======== Functions

#======== Main
#Print "the script name" and a small description of its function.
echo -e "${B}Disable root Account Script${RST}"
echo -e "${C}Reset password and disable local Adminsitrator Account.${RST}"

fn_directoryHasPermissions "./"                                      #Check the current directory permissions, for log creation

fn_logMessage cl $INF "Starting log"                                 #Clean the content and start the log

fn_supportedOS                                                       #Check for supported OSs.

fn_forceRoot                                                         #Check for Administrator rights


task="Generate new Root Password."                                   #Generate a radom password
fn_printTask "${RUNN}" "${task}"
new_root_pass="$(cat /dev/urandom | tr -cd '[:graph:]' | head -c 18)"
fn_execStatus $? "${task}"

task="Reset root password."                                          #Reset root password
fn_printTask "${RUNN}" "${task}"
echo "root:${new_root_pass}" | sudo chpasswd
fn_execStatus $? "${task}"
fn_printMessage "${INF}" "This is the new root password, please store it in somewhere safe."
echo -e "  ${INF} Password: ${Y}${new_root_pass}${RST}"

task="Lock root account password."                                   #Lock root password
fn_printTask "${RUNN}" "${task}"
passwd -ql root
fn_execStatus $? "${task}"

if dpkg -l | grep -iq openssh-server; then
  fn_printTask nl "${OK}" "Disable SSH Login."                       #If openssh-server is installed, disable root login 
  task="Disable SSH Login."
  fn_printTask "${RUNN}" "${task}"
  if $(grep -qE '^\s*PermitRootLogin' /etc/ssh/sshd_config); then
    sed -i 's/^\s*PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
  else 
    sed -i '34 i PermitRootLogin no' /etc/ssh/sshd_config
  fi 
  fn_execStatus $? "${task}"

  task="Reload SSHD configuration"                                   #If openssh-server is installed, reload the service 
  fn_printTask "${RUNN}" "${task}"
  systemctl reload ssh
  fn_execStatus $? "${task}"
else
  fn_printTask nl "${KO}" "Disable SSH Login."
  fn_printTask nl "${SKIP}" "Disable SSH Login."
  fn_printTask nl "${SKIP}" "Reload SSHD configuration"
fi