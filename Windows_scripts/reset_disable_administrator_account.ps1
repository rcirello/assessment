#Author: Renan Cirello
#E-mail: rcirello@gmail.com
#Purpose: Scripting Skills Assessment
#Script: Reset Administrator password and disable the account
<#
.SYNOPSIS
Reset Administrator password and disable the account.
  
.DESCRIPTION
 - Get system's administration account (Language independent)
 - Generate a random password, which is informed to the user, but not logged
 - Generate the password secure string
 - Change Administrator account
 - Disable Administrator account
  
.EXAMPLE
reset_disable_administrator_account.ps1
  
.NOTES
This script will not change root user shell configration, third 
party scripts could make use of root's shell to execute operations.
The usage of nologin shell can generate future problemas, so the
account's password and SSH access will be blocked.
#>

#======== Configurations
$SUPPORTED_OS_VERSIONS=@('Windows 10')                 #Comment this line to run the script withou OS Version limitations.
$LOG_FILE_NAME='account_management_log.txt'                          #Log file

#======== Script's Vars
$SCRIPT_NAME=$myInvocation.MyCommand.Name
#$AdministratorGroupSID="S-1-5-32-544"                               #Default SID for Administrator group.
$AdministratorUserSID="S-1-5-21-*-500"                               #Default SID for Administrator user.

#======== Support Functions
if ( Test-Path functions.ps1 -PathType Leaf ) {
  . .\functions.ps1
} else {
  Write-Host "[ERROR] Missing function.ps1 file."
  exit 1
}

#======== Script's Functions

function fn_generateRandomPassword(){
  <#
  .SYNOPSIS
  Generate and return a Random password.
  
  .DESCRIPTION
  Generate and return a Random password.
  
  .EXAMPLE
  fn_generateRandomPassword
  
  .NOTES
  
  #>
  $local:length = 18
  $local:chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?'
  $local:randomPassword = -join (1..$local:length | ForEach-Object { Get-Random -InputObject $local:chars.ToCharArray() })
  return "$local:randomPassword"
}
#======== Main
#Print "the script name" and a small description of its function.
Write-Host -BackgroundColor Black -ForegroundColor Blue "Disable Administrator Account Script"
Write-Host -BackgroundColor Black -ForegroundColor DarkCyan "Reset password and disable local Adminsitrator Account."

fn_folderHasPermissions ".\"                                         #Check the current directory permissions, for log creation

fn_logMessage cl $INFO.Object "Starting log"                         #Clean the content and start the log

fn_supportedOS                                                       #Check for supported OSs.

fn_forceAdministrator                                                #Check for Administrator rights

$task="Get System's Administrator Account."
fn_printTask "RUNN" $task                                            #Get the Administrator Account using the default SID, to avoid deal with different system languages.
$localAdministratorAccount = Get-LocalUser | Where-Object -Property SID -like $AdministratorUserSID
fn_execStatus $? "$task"

$task="Generate new Administrator Password."                         #Generate a random password
fn_printTask "RUNN" $task
$newPassword = $(fn_generateRandomPassword)                          
fn_execStatus $? "$task"
fn_printMessage 'INFO' "Save the new Administrator password properly!"
Write-Host "  Password: $newPassword"                                #Advise the the user to store the password and print it on the screen, but don't log it.

$task="Make the password a secure string."                           #Make the password a secure string
fn_printTask "RUNN" $task
$securePasswordString = $newPassword | ConvertTo-SecureString -AsPlainText -Force
fn_execStatus $? "$task"

$task="Update Administrator password."                               #Update Administrator password.
fn_printTask "RUNN" $task
Set-LocalUser -Name $localAdministratorAccount -Password $securePasswordString
fn_execStatus $? "$task"

$task="Ensure Administrator account is disabled"                     #Disable Administrator account.
fn_printTask "RUNN" $task
Disable-LocalUser -Name $localAdministratorAccount
fn_execStatus $? "$task"