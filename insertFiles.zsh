#!/bin/zsh
# written by Aaron Ciuffo (aaron.ciuffo@gmail.com)
# https://github.com/txoof/insertFiles

# add test results into Google Drive portfolio folders over google filestream

# update this if the name of the shared drive changes
mySharedDriveName="ASH Student Cumulative Folders"

# root of Google Shared Drives
mySharedRoot="/Volumes/GoogleDrive/Shared drives/"






# full path to shared drive
mySharedDrive=${mySharedRoot}${mySharedDriveName}/

# check that this file exists before attempting to do anything
checkFile="checkFile_DO_NOT_REMOVE.txt"

# set the long name and short name for the application
myLongName='com.txoof.'`basename $0`
myName=`basename "$0"`


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




if [[ $# -lt 1 ]]; then
  usage
fi

if [[ ! -f $mySharedDrive/$checkFile ]]; then
  echo "FATAL ERROR!"
  echo "Check file is missing from $mySharedDriveName"
  echo " "
  echo "Check the following :"
  echo "     * Google File Stream is running and signed in"
  echo "     * Check the name of the Google Shared Drive"
  echo "          * expected name: $mySharedDriveName"
  echo "     * $checkFile exists in $mySharedDrive"
  echo " "
  echo "If '$checkFile' is missing from the Shared drive,"
  echo "it can be recreated by opening the terminal app typing the following command:"
  echo " "
  echo "touch $mySharedDrive/$checkFile"
  echo " "
  echo "exiting - cannot continue without checkfile"
  exit 0
fi


# create a directory cache of folders stored in sharedDrive
myTempDir=$TMPDIR${myLongName}
dirCache=$myTempDir/sharedDriveCache.txt

if [[ ! -d $myTempDir ]]; then
  mkdir $myTempDir
fi

find "${mySharedDrive}" -maxdepth 3 -type d > $dirCache

# set the current school year
mySchoolYear=`schoolYear`

# loop through each file provided on the command line
for each in "${@}"
do
  # extract the student number from each file
  stuNumber=`echo ${each} | sed 's/.*[^0-9]\([0-9]\{5,10\}\).*\.pdf$/\1/g'`
  studentDir=`grep $stuNumber "${dirCache}"`
  newName=${mySchoolYear}_`basename $each`
  echo copy ${each} ${studentDir}/${newName}
done

