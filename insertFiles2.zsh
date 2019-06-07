#!/bin/zsh
# set the shared drive name for the portfolio folder
mySharedDriveName="ASH Student Cumulative Folders"
# the name of the folder(s) that contains all of the cum folders
# this should be relative to mySharedDrive
myCumFolder="Student Cumulative Folders (AKA Student Portfolios)"

# root of Google Shared Drives
mySharedRoot="/Volumes/GoogleDrive/Shared drives/"



# TODO fix all function variables so they are local variables

##################################
# Functions
schoolYear() {
  # return the school year string based on the current date
  local curMonth=`date '+%m'`
  local curYear=`date '+%Y'`
  if [[ $curMonth -ge 1 ]] && [[ $curMonth -le 07 ]]; then
    local endYear=$curYear
    local startYear=$((curYear-1))
  else
    endYear=$((curYear+1))
    startYear=$curYear
  fi
  # return string with sy value
  echo "SY$startYear-$endYear"
}

usage() { 
  # usage instructions
  if [[ ${#[@]} -lt 1 ]]; then
    printf "$myName inserts multiple test files into a Google Shared drive
folder based on student numbers 

command line usage:
$myName [--<grade sub-folder>] StudentID-File1 FileN-StudentID
$myName [--<grade sub-folder>] /path/to/files/.*

Grade Sub Folders: --ps, --tk, --kg, --1..--12

EXAMPLE:
Insert all PDFs in ~/Downloads/grade3 into 03-Grade sub folders
$] $myName --3 ~/Downloads/grade3/*.pdf

point and click use: drag multiple documents into this window

written by Aaron Ciuffo - aaron.ciuffo@gmail.com
updates at: https://github.com/txoof/insertFiles"
    exit 0
  fi
}

checkSentry() {
  # check for sentry file on Google Shared drive
  # exit out if sentry file is missing
  if [[ ! -f $mySharedRoot/$mySharedDriveName/$sentryFile ]]; then
printf "FATAL ERROR
Sentry file is missing from $mySharedDriveName

Check the following :
     * Google File Stream is running and signed in
     * Check the name of the Google Shared Drive
          * expected name: $mySharedDriveName
     * $checkFile exists in $mySharedDrive

If '$checkFile' is missing from the Shared drive,
it can be recreated by opening the terminal app typing the following command:

touch \"$mySharedDrive/$sentryFile\"

exiting"
    exit 0
  fi
}

cacheDirs() {
  # create cache directory
  if [[ ! -d $myTempDir ]]; then
    mkdir $myTempDir
  fi

  # check for sentry file on shared drive
  checkSentry

  # create the cache file
  find "${mySharedDrive}" -maxdepth 2 -type d > $driveCache
  if [[ $? -gt 0 ]]; then
    echo "caching of remote directories failed"
    echo "See $driveCache for more details"
    echo "exiting"
    exit 1
  fi
}

parseArgs() {
  # parse the command line arguments
  local argOne=$1
  local regexp="--([0-9]+)"

  local gradeFolders=(00-Preschool 00-Transition 00-zKindergarten 01-Grade 02-Grade 03-Grade 04-Grade 05-Grade 06-Grade 07-Grade 08-Grade 09-Grade 10-Grade 11-Grade 12-Grade)

  # check for an a grade level argument (--ps, --tk, --kg, --1, --12)
  [[ $argOne =~ $regexp ]]
  local gradeLevel=${match[1]}
  local gradeIndex=$((gradeLevel+3))

  case $argOne in
    --ps)
      local gradeFolder=$gradeFolders[1]
      ;;
    --tk)
      local gradeFolder=$gradeFolders[2]
      ;;
    --kg)
      local gradeFolder=$gradeFolders[3]
      ;;
    --1|--2|--3|--4|--5|--6|--7|--8|--9|--10|--11|--12)
      local gradeFolder=$gradeFolders[$gradeIndex]
      ;;
    *)
      printf "Unknown option: $argOne\n\n"
      usage
  esac

  echo $gradeFolder
}

execute() {
  "$@"
  local mystat=$?
  if [ $mystat -ne 0 ]; then
    echo "error with $1" >&2
  fi
  echo $mystat
}

insertFiles() {
  local failCopy=()
  local failCache=()
  local failFileName=()
  local success=()
  for each in "${fileArgs[@]}"
  do
    local match=()
    # capture 5 or more consecutive digits in supplied ilename
    [[ $each =~ "([0-9]{5,})" ]]
    if [[ ${#match[1]} -gt 0 ]]; then
      local stuNum=${match[1]}
      # grep and attempt to insert file into path here
      studentDir=$(exec grep "$stuNum" "${driveCache}")
      echo %%%%%%%%%%%%%%%
      echo $studentDir
      if [[ $? -gt 0 ]]; then
        failCache+=$each
        continue
      fi

      #echo cp $each to $studentDir

    else
      failFileName+=$each
    fi
  done

}
##################################
# main

# set the program  name
[[ `basename ${0}` =~ "(^.*)\..*" ]]
myName=${match[1]}
myLongName="com.txoof."${myName}
mySharedDrive=${mySharedRoot}/${mySharedDriveName}/${myCumFolder}

# check for arguments - give usage instructions if no arguments
usage $@

# if gradelevel switch is provided, set a sub folder within the student folder
gradeFolder=$(parseArgs $1)

# discard switches; keep file arguments
if [[ $1 =~ "^--.*" ]]; then
  fileArgs=(${@:2})
else
  fileArgs=($@)
fi

# check that file arguments were provided
if [[ ${#fileArgs[@]} -lt 1 ]]; then
  # if not, give usage instructions
  usage
fi

# set temp directory for cache
myTempDir=$TMPDIR${myLongName}
driveCache=$myTempDir/sharedDriveCache.txt
# sentry file that indicates this is the proper Shared drive
# if file is missing, bail out
sentryFile="sentryFile_DO_NOT_REMOVE.txt"

# cache the files on the shared drive for faster searching
cacheDirs

insertFiles $fileArgs


