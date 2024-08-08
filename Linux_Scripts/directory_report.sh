#!/bin/bash
#Author: Renan Cirello
#E-mail: rcirello@gmail.com
#Purpose: Scripting Skills Assessment
#Script: Directory file report

#.SYNOPSIS
#Generate a report of files inside of a given directory
  
#.DESCRIPTION
# - Receive a parameter with the directory path, or ask for it
# - Check if the path is a directory
# - Check if the user has permissions on the path
# - Generate the report
  
#.EXAMPLE
#directory_report.sh "<path>"
#directory_report.sh
  
#.NOTES

#======== Configurations
SUPPORTED_OS_VERSIONS=("Ubuntu:20.04")                    #Comment this line to run the script withou OS Version limitations.
REPORT_FILE_NAME='directory_report.txt'                              #Report File
SCRIPT_NAME="${0}"

#======== Support Functions
source functions.sh

#======== Script's Functions
fn_generateReport(){
  #.SYNOPSIS
  #Generate report containing the files from a fiven folder.
  
  #.DESCRIPTION
  #Generate a report containing:
  # - A pre-defined header.
  # - A body containing the files found at a given folder.
  # - Inform the user where the report is located.
  # - Advise the user to view the report on excel.

  #The report name can be changed by redefining the REPORT_FILE_NAME at the 
  #beginning of the script.
  
  #.EXAMPLE
  #fn_generateDirectoryReport
  
  #.NOTES

  local l_path="${1}"
  local l_reportFullPath=$( echo "${l_path}/${REPORT_FILE_NAME}" | sed 's/\/\//\//g')
  local l_task="Set report header."

  fn_printTask "RUNN" "${l_task}"                                    #Create the report file, while cleaning its content and add a header.
  echo "Directory Report,,Generated at:$(date -R | cut -d',' -f2)
Report Format: CSV
Options:
  - Recursive: False
  - Type: Files Only
Name;Size (B);Last Modified" > "${l_reportFullPath}"
  fn_execStatus $? "$l_task"

  l_task="Get report data."                                          #List the files inside the given directory
  fn_printTask "RUNN" "${l_task}"
  local l_reportData="$(ls -l --time-style="+%F %r %z" "${l_path}" | grep -v '^d' | awk '{ print $10","$5","$6,$7$8,$9 }' | grep -v '^,,' | sed 's/\/\//\//g')"
  fn_execStatus $? "$l_task"

  l_task="Set report body."                                          #Add the files to the report.
  fn_printTask "RUNN" "${l_task}"
  echo "${l_reportData}" >> "${l_reportFullPath}"
  fn_execStatus $? "$l_task"
                                                                     #Inform the user the report location and adivise it to use Excel for a better visualization.
  fn_printMessage "$INF" "The generated report can be found at ${O}${l_reportFullPath}${RST}."
  fn_printMessage "$INF" "For better visualization is recommended to move its data to Excel and split columns by comma."
}

#======== Main
#Print "the script name" and a small description of its function.
echo -e "${B}Directory File Listing Script${RST}"
echo -e "${C}Generates a file's report from a given folder.${RST}"

directory_path="${1}"

if [ -z "${directory_path}" ] || [ "${directory_path}" == "" ]; then
  echo -n "To generate the report, please enter the desired directory path:"
  read directory_path
fi 

fn_supportedOS                                                       #Check for supported OSs.

fn_isDirectory "${directory_path}"                                   #Check if the given path is a folder.

fn_directoryHasPermissions "${directory_path}"                       #Check if the given path hass the minimal permissions needed.

fn_generateReport "${directory_path}"                                #Generates the file report

