#Author: Renan Cirello
#E-mail: rcirello@gmail.com
#Purpose: Scripting Skills Assessment
#Script: System Patch Script
<#
.SYNOPSIS
#Patch OS with all available updates
  
.DESCRIPTION
 - Check for pending reboots
 - Check for available updates
 - Patch the system
 - Check installed updates
 - Check for pending reboots
  
.EXAMPLE
system_patch.ps1
  
.NOTES
This is a simple script, so automatic reboots will be avoided during the 
update steps, yet treated separatedly
#>
#======== Configurations
$SUPPORTED_OS_VERSIONS= @('Windows 10')                #Comment this line to run the script withou OS Version limitations.
$LOG_FILE_NAME='patch_log.txt'                                       #Log file
$SCRIPT_NAME=$myInvocation.MyCommand.Name

#======== Support Functions
if ( Test-Path functions.ps1 -PathType Leaf ) {
  . .\functions.ps1
} else {
  Write-Host "[ERROR] Missing function.ps1 file."
  exit 1
}

#======== Script's Functions

function fn_installPkgProvider(){
  <#
  .SYNOPSIS
  Install a given package provider.
  
  .DESCRIPTION
  Check if already installed and install a Package Provider
  
  
  .EXAMPLE
  fn_installPkgProvider "<Package Provider>"
  
  .NOTES
  
  #>
  $local:pkgProvider = $args[0]
  $local:task_installPkgProvider="Check if $local:pkgProvider Package Provider is installed."
  fn_printTask "RUNN" $local:task_installPkgProvider
  $local:isInstalled = Get-PackageProvider -ListAvailable -Name $local:pkgProvider

  if ([string]::IsNullOrEmpty($local:isInstalled)){                  #If not installed, install the package provider
    fn_printTask nl "WARN" $local:task_installPkgProvider

    $local:task_installPkgProvider="Install $local:pkgProvider Package Provider" 
    fn_printTask "RUNN" $local:task_installPkgProvider 
    $local:pkgProviderInstall = Install-PackageProvider -Name $local:pkgProvider -Force
    fn_execStatus $? "$local:task_installPkgProvider"

    fn_logMessage $INFO.Object "$(Out-String -InputObject $local:pkgProviderInstall)"
    
  } else {
    fn_printTask nl "OK" $local:task_installPkgProvider  
  }
}

function fn_installPSModule(){
  <#
  .SYNOPSIS
  Short description
  
  .DESCRIPTION
  Check if a given module is already installed:
  - If installed, just import the pa
  - If not installed, install and import the module
  
  .EXAMPLE
  fn_installPSModule "PS Module"
  
  .NOTES
  
  #>
  $local:psModule = $args[0]
  $local:task_installPSModule="Check if $local:psModule module is installed."
  fn_printTask "RUNN" $local:task_installPSModule
  $local:isInstalled = Get-Module -ListAvailable -Name $local:psModule

  if ([string]::IsNullOrEmpty($local:isInstalled)){                  #If not installed, install the PS Module
    fn_printTask nl "WARN" $local:task_installPSModule

    $local:task_installPSModule="Install $local:psModule Module"
    fn_printTask "RUNN" $local:task_installPSModule
    Install-Module -Name $local:psModule -Force 
    fn_execStatus $? "$local:task_installPSModule"

  } else {
    fn_printTask nl "OK" $local:task_installPSModule  
  }

  $local:task_installPSModule="Import $local:psModule Module"        #Import PS Module
  fn_printTask "RUNN" $local:task_installPSModule
  Import-Module -Name $local:psModule -Force 
  fn_execStatus $? "$local:task_installPSModule"
}

function fn_checkPendingReboot(){
  <#
  .SYNOPSIS
  Check for pending reboots
  
  .DESCRIPTION
  Check for pending reboots and end script execution if called with 'es' as 
  parameter.
  
  .EXAMPLE
  fn_checkPendingReboot 'es'
  fn_checkPendingReboot
  
  .NOTES
  General notes
  #>
  $local:endScript = $args[0]
  $local:pendingReboot = $false
  $local:task="Check for Pending Reboot."
  fn_printTask "RUNN" $local:task
  $local:pendingReboot = Test-PendingReboot -SkipConfigurationManagerClientCheck
  if ( $local:endScript -match 'es' ) {                              #When match the es string, the function will throw an error
    if ( $local:pendingReboot.isRebootPending ){                     #and finish the script execution.
      fn_execStatus $false "$local:task" "A Pending Reboot was found, please reboot your system before continue."
    } else {
      fn_execStatus $true "$local:task"
    }
  } else {
    if ( $local:pendingReboot ){
      fn_execStatus $true "$local:task"
      fn_printMessage 'WARN' "A Pending Reboot was found in this computer, consider Reboot it as soon as possible."
    }
  }
  
}

#======== Main
#Print "the script name" and a small description of its function.
Write-Host -BackgroundColor Black -ForegroundColor Blue "System Patching Script"
Write-Host -BackgroundColor Black -ForegroundColor DarkCyan "Check, Update and Log system's patch data."

fn_folderHasPermissions ".\"                                         #Check the current directory permissions, for log creation

fn_logMessage cl $INFO.Object "Starting log"                         #Clean the content and start the log

fn_supportedOS                                                       #Check for supported OSs.

fn_forceAdministrator                                                #Check for Administrator rights

fn_logMessage $INFO.Object "Starting System Patch"                   #Log patching operation start

fn_installPkgProvider "NuGet"                                        #Install NuGet Package Provider

fn_installPSModule "PSWindowsupdate"                                 #Install PSWindowsupdate Module

fn_installPSModule "PendingReboot"                                   #Install Pending Reboot Module

fn_checkPendingReboot 'es'                                           #Check for pending reboots and end the script if there is one.

$task="Check Available Updates"                                      #Check available Updates
fn_printTask "RUNN" $task
$availableUpdates = Get-WindowsUpdate -IgnoreReboot *>&1             
fn_execStatus $? "$task"                                             
fn_logMessage $INFO.Object "$(Out-String -InputObject $availableUpdates)"

$task="Install Available Updates"                                    #Install available Updates
fn_printTask "RUNN" $task
$updatesInstall = Get-WindowsUpdate -WindowsUpdate -AcceptAll -Install -IgnoreReboot *>&1
fn_execStatus $? "$task"
fn_logMessage $INFO.Object "$(Out-String -InputObject $updatesInstall)"

$task="Check Installed Updates"                                      #Check Installed Updates
fn_printTask "RUNN" $task
$installedUpdates = wmic qfe list
fn_execStatus $? "$task"
fn_logMessage $INFO.Object "$(Out-String -InputObject $installedUpdates)"

fn_checkPendingReboot                                                #Check for pending reboots and ward the user about it.
                                                                     #Inform the user the log location
fn_printMessage 'INFO' "Log information can be found at $LOG_FILE_NAME file."

fn_logMessage $INFO.Object "System Patch Ended"                      #Log patching operation end