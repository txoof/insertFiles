#!/bin/zsh
# written by Aaron Ciuffo (aaron.ciuffo@gmail.com)
# https://github.com/txoof/insertFiles

# add files that contain student numbers into Google Drive portfolio folders 
# over google filestream

# set the shared drive name for the portfolio folder
mySharedDriveName="ASH Student Cumulative Folders"

# root of Google Shared Drives
mySharedRoot="/Volumes/GoogleDrive/Shared drives/"


####################################################

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


# main

# check if there were files were provided as arguments
if [[ $# -lt 1 ]]; then
  usage
fi

# a check file resides in the root of the team drive
# if the check file is missing, exit out
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

# array of failed and successful copy opperations
cpFail=()
cpSuccess=()
notFound=()

# loop through each file provided on the command line
for each in "${@}"
do
  # extract the student number from each file
  stuNumber=`echo ${each} | sed 's/.*[^0-9]\([0-9]\{5,10\}\).*/\1/g'`
  # locate path in cache
  studentDir=`grep $stuNumber "${dirCache}"`
  # handle files with student numbers that are not present in Cummulative folder 
  if [[ $? -gt 0 ]]; then
    notFound()+=($each)
    cpFail+=($each)
    echo "Could not find matching google drive folder for student:"
    echo "$each"
  else
    newName=${mySchoolYear}_`basename $each`
    cp ${each} ${studentDir}/${newName}
    if [[ $? -gt 0 ]]; then
      cpFail+=($each)
    else
      cpSuccess+=($each)
    fi
  fi
done

echo " "
echo " "

# show the failed files
if [[ ${#cpFail[@]} -gt 0 ]]; then
  echo "Failed to insert these files - see errors above"
  printf "%s\n" "${cpFail[@]}"
fi

# show the successful files
if [[ ${#cpSuccess[@]} -gt 0 ]]; then
  echo " "
  echo "Successfully inserted ${#cpSuccess[@]} of ${#[@]} files"
fi


# remind the user how to use the application - useful in platypus application
echo " "
echo " "
