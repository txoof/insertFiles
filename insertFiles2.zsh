#!/bin/zsh
# set the shared drive name for the portfolio folder
mySharedDriveName="ASH Student Cumulative Folders"

# root of Google Shared Drives
mySharedRoot="/Volumes/GoogleDrive/Shared drives/"


##################################
# Functions
schoolYear() {
  # return the school year string based on the current date
  curMonth=`date '+%m'`
  curYear=`date '+%Y'`
  if [[ $curMonth -ge 1 ]] && [[ $curMonth -le 07 ]]; then
    endYear=$curYear
    startYear=$((curYear-1))
  else
    endYear=$((curYear+1))
    startYear=$curYear
  fi
  # return string with sy value
  echo "SY$startYear-$endYear"
}

usage() {
  # usage instructions
  echo "$myName: inserts multiple test files into a Google Shared drive"
  echo "folder based on student numbers"
  echo "=========================="
  echo "command line use:"
  echo "  $] $myName TEST_LNameFname_000001.pdf TEST_LNameFname_000002.pdf TEST_LNameFname_00000N.pdf"
  echo "  $] $myName /path/to/*.pdf"
  echo "=========================="
  echo "point and click use: drag multiple test result documents into this window"
  echo ""
  echo "written by Aaron Ciuffo - aaron.ciuffo@gmail.com"
  echo "updates at: https://github.com/txoof/insertFiles"
  exit 0
}

##################################
# main

# set the program  name
[[ `basename ${0}` =~ "(^.*)\..*" ]]
myName=${match[1]}

echo $myName
