#Author: Renan Cirello
#E-mail: rcirello@gmail.com
#Purpose: Scripting Skills Assessment
#Script: Functions

#== Functions Configuration
#Force commands to continue silently on error, the errors should be handled by the scripts.
$ErrorActionPreference=[System.Management.Automation.ActionPreference]::SilentlyContinue

#== Status Messages
#Pre-defined status messages
$OK=   @{ ForegroundColor = 'Green' ; NoNewLine = $true; Object = "[SUCCESS] " }
$KO=   @{ ForegroundColor = 'Red'   ; NoNewLine = $true; Object = "[FAILED] " }
$INFO= @{ ForegroundColor = 'White' ; NoNewLine = $true; Object = "[INFO] " }
$WARN= @{ ForegroundColor = 'Yellow'; NoNewLine = $true; Object = "[WARNING] " }
$ERR=  @{ ForegroundColor = 'Red'   ; NoNewLine = $true; Object = "[ERROR] " }
$RUNN= @{ ForegroundColor = 'Yellow'; NoNewLine = $true; Object = "[RUNNING] " }

#== Tasks
#Variables used to give a more homogeneous visual when printing information on
$TASK_STRING_SIZE=30 #The screen
$LOG_STRING_SIZE=10  #The log

#== Support Functions
function fn_execStatus(){
  <#
  .SYNOPSIS
  Function to help check the exit code from command execution and manage 
  tasks status
  
  .DESCRIPTION
  Receive a exit code ($?) or a boolean to return the related 
  string (Succes/Failed) and a custom error message for that task.
  The custom error message is a optional paramenter.
  The script execution is ended if an error state is passed.

  
  .EXAMPLE
  fn_execStatus $? "<Task String>" "<Error Message String>"
  fn_execStatus $true "<Task String>" 
  fn_execStatus $false "<Task String>" "<Error Message String>"
  
  .NOTES
  
  #>
  $local:exitStatus=$args[0]
  $local:msgString=$args[1]
  $local:msgStringErr=$args[2]
  
  if ( $local:exitStatus ) {
    fn_printTask nl 'OK' "$local:msgString"
  } else {
    fn_printTask nl 'KO' "$local:msgString"
    if ( -Not ([string]::IsNullOrEmpty($local:msgStringErr))) { 
      fn_printMessage 'ERR' "$local:msgStringErr"
    }
    exit 1
  }
}

function fn_printTask(){
  <#
  .SYNOPSIS
  Function to help inform the steps executed by the script to the user..

  .DESCRIPTION
  This function was made to inform the user about what is being executed by the
  scritpt.
  It allows rewriting task lines giving "a dynamic sense" that the 
  steps are running, and the opportunity to keep only final status
  on the screen.
  
  .EXAMPLE
  #Print a task an move to the next line
  fn_printTask nl "<Status String>" "<Message String>"

  #Print a task but keep the cursor at the same line, allowing to rewrite that line.
  fn_printTask "<Status String>" "<Message String>"
  
  .NOTES
  
  #>
  if ( $args[0] -match 'nl' ) {                                      #Check whether to move to next line or not
    $local:writeOpts=@{ NoNewLine = $false }                         
    $local:statusString=Get-Variable $args[1] -ValueOnly
    $local:msgString=$args[2]
  }
  else {
    $local:writeOpts=@{ NoNewLine = $true }                          
    $local:statusString=Get-Variable $args[0] -ValueOnly
    $local:msgString=$args[1]
  }
  
  $local:statusSize=$local:statusString.Object.Length                #Get the size of the status string to manipulate the log output.
  $local:fillingChars="-"*($TASK_STRING_SIZE - $local:statusSize)    #The idea is to give homogeneous view of the script output.
  
  Write-Host -NoNewline "`r* "
  Write-Host @local:statusString
  Write-Host @local:writeOpts $local:fillingChars-> $local:msgString
  fn_logMessage $local:statusString.Object "$local:msgString"        #Call the fn_logMessage to log the operation
 
}

function fn_printMessage(){
  <#
  .SYNOPSIS
  Print a message to the user.
  
  .DESCRIPTION
  Print a message to the user and call the fn_logMessage to log it.
  
  .EXAMPLE
  fn_printMessage "<Status String>" "<Message String>"
  
  .NOTES
  
  #>
  $local:statusString=Get-Variable $args[0] -ValueOnly
  $local:msgString=$args[1]
  
  Write-Host -NoNewline "  "
  Write-Host @local:statusString
  Write-Host $local:msgString
  fn_logMessage $local:statusString.Object "$local:msgString"
  
}

function fn_supportedOS(){
  <#
  .SYNOPSIS
  Ensure the script will only run under tested/supported Operating Systems.
  
  .DESCRIPTION
  This function is based on the definition of the $SUPPORTED_OS_VERSIONS var,
  an array which contains strings that could be matched with the OSName 
  property from the Get-ComputerInfo command.
  If the OS is not supported the user receive an error and a list of
  supported OSs.
  If the $SUPPORTED_OS_VERSIONS is not defined, the function will not be
  executed.
  
  .EXAMPLE
  fn_supportedOS 
  
  .NOTES
  #>
    
  $local:isSupported=$false
  $local:task="Check OS support."
  fn_printTask "RUNN" $local:task

  if ( -Not ([string]::IsNullOrEmpty($SUPPORTED_OS_VERSIONS))) {     #Check if there $SUPPORTED_OS_VERSIONS is defined.
    $local:osName=Get-ComputerInfo -Property "OSName"                #Get OSName Property.

    foreach ($local:OsVersion in $SUPPORTED_OS_VERSIONS) {           #Iterate over Supported OS Versions.
      if ( $local:osName.OSName -Like "*$local:OsVersion*"  ) {      #Check if OSName match the supported OS.
        $local:isSupported=$true                                     #If true change the var name and break the loop.
        break                                                         
      }      
    }

    if ( -Not $local:isSupported ) {                                
      $local:osVersionsList=($SUPPORTED_OS_VERSIONS -join ' / ' )    #When not supported, the user receive a list of the defined supported OSs.
      fn_execStatus $false "$local:task" "This script only support the following OSs: $local:osVersionsList"
    } else {
      fn_execStatus $true "$local:task"
    }
    
  }
}

function fn_forceAdministrator(){
    <#
  .SYNOPSIS
  Ensure the script is running under the Administrator role.
  
  .DESCRIPTION
  This function use the WindowsIdentity Classe to create an object with the
  current user data and match if it currently has Administrator rights.
  
  .EXAMPLE
  fn_forceAdministrator 
  
  .NOTES
  #>

  $local:task="Check Administrative rights."
  fn_printTask "RUNN" $local:task

  $local:currentID=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  if ( -Not ($local:currentID.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) ) { 
    fn_execStatus $false "$local:task" "This script must be executed with Administrator rights."
  } else {
    fn_execStatus $true  "$local:task"
  }

}

function fn_folderHasPermissions {
  <#
  .SYNOPSIS
  Ensure a given folder has minimal read/write permissions.
  
  .DESCRIPTION
  This function tries to open a test file for writing, to check if the current
  user executing the script has enough permissions on it and trhows an error
  if it is not, informing the user the needed permissions.
    
  .EXAMPLE
  fn_folderHasPermissions "<folder>"
  
  .NOTES
  #>
  $local:path=$args[0]

  $local:task="Check path permissions."
  fn_printTask "RUNN" $local:task
  $local:hasFolderPermissions=$true                                      
  Try { [io.file]::OpenWrite("$local:path\write_test.txt").close() } #Try to open the test file for writing.
   Catch { $local:hasFolderPermissions=$false }                      #If any error is received it the user will receive a message to review its permissions and the script will end.
  fn_execStatus $local:hasFolderPermissions "$local:task" "Ensure you have read/write permissions on the provided path, or ask your System Administrator to review it (Path: $local:path)."  
}

function fn_isFolder(){
  <#
  .SYNOPSIS
  Check if a given path is a folder or not
  
  .DESCRIPTION
  For this context, this function check if the given path is a folder, throwing
  an error and ending the script if it is not.
    
  .EXAMPLE
  fn_isFoler "<path>"

  .NOTES

  #>
  $local:path=$args[0]

  $local:task="Check if path is a folder."
  fn_printTask "RUNN" $local:task
  if ( Test-Path -Path "$local:path" -PathType Container ){
    fn_execStatus $true "$local:task"
  } else {
    fn_execStatus $false "$local:task" "This script only accepts folders as parameters, please review you input data (Path: $local:path)."
  }
}

function fn_logMessage(){
  <#
  .SYNOPSIS
  Allow to log script operations into a pre-defined log file.
  
  .DESCRIPTION
  This function is based on the definition of the $LOG_FILE_NAME var,
  a simple string containing the file in which the operations should be
  logged into.
  
  If the variable $SCRIPT_NAME is also defined, the function log the messages
  containing also the script name.
  
  If the $LOG_FILE_NAME is not defined, the function will not be
  executed.
  
  The function can clean the file content and add a log message or simply add
  the log message
  
    
  .EXAMPLE
  #Clean the log file content and log a message
  fn_logMessage cl "<status string>" "<message string>" 

  #Log a message
  fn_logMessage cl "<status string>" "<message string>" 

  .NOTES
  Possible Log Formats:
  [Date/Time] [Script Name] [Status] [Log message]
  [Date/Time] [Status] [Log message]
  #>

  if ( -Not ([string]::IsNullOrEmpty($LOG_FILE_NAME)) ){             #Check if $LOG_FILE_NAME is defined.
    if ( $args[0] -match 'cl' ) {                                    #Check if the first argument is the 'cl' string.
      $local:statusString=$args[1]
      $local:msgString=$args[2]                                      #When True, the function use the Set-Content command to clean file contet.
      Set-Content -Path "$LOG_FILE_NAME" -Value ""  
    }
    else {
      $local:statusString=$args[0]
      $local:msgString=$args[1]
    }
              
    $local:statusSize=$local:statusString.Length                     #Get the size of the status string to manipulate the log output.
    $local:fillingChars=" "*($LOG_STRING_SIZE - $local:statusSize)   #The idea is to give a "field aspect" to the log files, making it easy to read. 
    
    if ( -Not ([string]::IsNullOrEmpty($SCRIPT_NAME)) ){             #Check if $SCRIPT_NAME is defined, to add or not the script on the log lines.
      $local:scriptName="[$SCRIPT_NAME] "
    }
    
    Add-Content -Path "$LOG_FILE_NAME" -Value "[$(Get-Date)] $local:scriptName$local:statusString$local:fillingChars$local:msgString"
  }
}