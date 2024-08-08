#Author: Renan Cirello
#E-mail: rcirello@gmail.com
#Purpose: Scripting Skills Assessment
#Script: Directory file report
<#
.SYNOPSIS
Reset Administrator password and disable the account.
  
.DESCRIPTION
 - Receive a parameter with the directory path, or ask for it
 - Check if the path is a directory
 - Check if the user has permissions on the path
 - Generate the report
  
.EXAMPLE
directory_report_script.ps1 "<path>"
directory_report_script.ps1
  
.NOTES
#>

#======== Configurations
$SUPPORTED_OS_VERSIONS= @('Windows 10')                #Comment this line to run the script withou OS Version limitations.
$REPORT_FILE_NAME='directory_report.txt'                             #Report File

#======== Support Functions
. .\functions.ps1

#======== Script's Functions

function fn_generateDirectoryReport(){
  <#
  .SYNOPSIS
  Generate report containing the files from a fiven folder.
  
  .DESCRIPTION
  Generate a report containing:
   - A pre-defined header.
   - A body containing the files found at a given folder.
   - Inform the user where the report is located.
   - Advise the user to view the report on excel.

  The report name can be changed by redefining the $REPORT_FILE_NAME at the 
  beginning of the script.
  
  .EXAMPLE
  fn_generateDirectoryReport
  
  .NOTES
  #>
  $local:folder= $args[0]
  $local:reportPath="$local:folder\$REPORT_FILE_NAME"                
  
  $local:task="Generate report header."                              #Report Header
  fn_printTask "RUNN" $local:task
  $local:header = @"
Directory Report,,Generated at: $(Get-Date)
Report Format: CSV
Options:
  - Recursive: False
  - Type: Files Only
"@
  fn_execStatus $? "$local:task"

  $local:task="Set report header."                                   #Create the report file, while cleaning its content and add a header.
  fn_printTask "RUNN" $local:task
  Set-Content -Path "$local:reportPath" -Value $local:header
  fn_execStatus $? "$local:task"

  $local:task="Get report data."                                     #List the files inside the given folder and convert it to CSV.
  fn_printTask "RUNN" $local:task
  $local:body= Get-ChildItem -File -Path $local:folder | Select-Object Name,@{Name='Size (B)'; Expression='Length'},@{Name='Last Modified'; Expression='LastWriteTime'} | ConvertTo-Csv -NoTypeInfo
  fn_execStatus $? "$local:task"

  $local:task="Set report body."                                     #Add the files to the report.
  fn_printTask "RUNN" $local:task
  Add-Content -Path "$local:reportPath" -Value $local:body
  fn_execStatus $? "$local:task"
                                                                     #Inform the user the report location and adivise it to use Excel for a better visualization.
  fn_printMessage 'INFO' "The generated report can be found at $($local:reportPath.replace('\\','\'))."
  fn_printMessage 'INFO' "For better visualization is recommended to move its data to Excel, or similar, and split columns by comma."
  
}

#======== Main

#Print "the script name" and a small description of its function.
Write-Host -BackgroundColor Black -ForegroundColor Blue "Directory File Listing Script"
Write-Host -BackgroundColor Black -ForegroundColor DarkCyan "Generates a file's report from a given folder."

$folderPath=$args[0]

if ([string]::IsNullOrEmpty($folderPath)){                          #Check if a path was given, if not prompts the user.
  $folderPath = Read-Host "To generate the report, please enter the desired directory path"
}

fn_supportedOS                                                      #Check for supported OSs.

fn_isFolder "$folderPath"                                           #Check if the given path is a folder.

fn_folderHasPermissions "$folderPath"                               #Check if the given path hass the minimal permissions needed.

fn_generateDirectoryReport "$folderPath"                            #Generates the file report