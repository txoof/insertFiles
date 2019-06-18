#!/bin/zsh
# set the shared drive name for the portfolio folder
mySharedDriveName="ASH Student Cumulative Folders"
# the name of the folder(s) that contains all of the cum folders
# this should be relative to mySharedDrive
myCumFolder="Student Cumulative Folders (AKA Student Portfolios)"

# root of Google Shared Drives as provided by FileStream
mySharedRoot="/Volumes/GoogleDrive/Shared drives/"



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
#  if [[ -z $1 ]]; then
    printf "$myName adds multiple files into a Google Shared drive
folder based on student numbers in the file names.

########################
Drag one or more files into this window to insert into Google Shared drive
cumulative folders.
########################

written by Aaron Ciuffo - aaron.ciuffo@gmail.com
updates at: https://github.com/txoof/insertFiles\n\n"


#command line usage:
#$myName [--<grade sub-folder>] StudentID-File1 FileN-StudentID
#$myName [--<grade sub-folder>] /path/to/files/.*

#Grade Sub Folders: --ps, --tk, --kg, --1..--12

#EXAMPLE:
#Insert all PDFs in ~/Downloads/grade3 into 03-Grade sub folders
#$] $myName --3 ~/Downloads/grade3/*.pdf

#Insertr all PDFs in ~/Downloads/G3-Map_results into student folders:
#$] $myName ~/Downloads/G3-Map_results/*.pdf 

  exit 0
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
     * $sentryFile exists in $mySharedDrive

If '$sentryFile' is missing from the Shared drive,
it can be recreated by opening the terminal app typing or pasting in
the following command:

touch \"$mySharedRoot/$mySharedDriveName/$sentryFile\"

exiting"
    exit 0
  fi
}

cacheDirs() {
  # cache the directories stored in the shared drive
  echo Creating cache file: $myTempDir
  # create cache directory
  if [[ ! -d $myTempDir ]]; then
    mkdir $myTempDir
  fi


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
  local gradeFolder="/"

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
#    *)
#      print "Unknown option: $argOne\n\n"
#      usage
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
  # insert files into appropriate folders
  local failCopy=()
  local failCache=()
  local failFileName=()
  local success=()
  print "Inserting ${#fileArgs[@]} files into $gradeFolder folder for each student: \n"
  for each in "${fileArgs[@]}"
  do
    local match=()
    local studentDir=''
    # capture 5 or more consecutive digits in supplied filename
    [[ $each =~ "([0-9]{5,})" ]]
    # check that there is something that looks like a student number
    if [[ ${#match[1]} -gt 0 ]]; then
      local stuNum=${match[1]}
    else
      failFileName+=($each)
      continue
    fi

    # check the cached directories for student numbers
    studentDir=$(eval grep $stuNum $driveCache)
    # check for successful completion
    if [[ $? -gt 0 ]]; then
      failCache+=($each)
      continue
    fi

    # copy the file into the appropriate directory
    #print "inserting $each"
    cp $each $studentDir/$gradeFolder

    if [[ $? -gt 0 ]]; then
      failCopy+=($each)
    continue
    fi

    # record each successful insertion here
    success+=($each)
  done

  # print results for failures and successes
  # successful insertions
  if [[ ${#success[@]} -gt 0 ]]; then
    printf "\nSuccessfully inserted ${#success[@]} of ${#fileArgs[@]} files\n"
  fi

  # failed due to filename issue
  if [[ ${#failFileName[@]} -gt 0 ]]; then
    printf "\nCould not process the following files - no student number in name:\n"
    printf "%s\n" "${failFileName[@]}"
  fi

  # failed due to student not existing in cache/on google drive
  if [[ ${#failCache[@]} -gt 0 ]]; then

    printf "\nCould not process following files - students not found on Shared Drive:\n"
    printf "%s\n" ${failCache[@]}
  fi

  # failed due to a copy problem
  if [[ ${#failCopy[@]} -gt 0 ]]; then
    printf "\nCould not process following files - error copying:\n"
    printf "%s\n" ${failCopy[@]}
  fi
}

##################################
# main

# set the program  name
[[ `basename ${0}` =~ "(^.*)\..*" ]]
myName=${match[1]}
myLongName="com.txoof."${myName}
mySharedDrive=${mySharedRoot}/${mySharedDriveName}/${myCumFolder}

# if gradelevel switch is provided, set a sub folder within the student folder
if [[ -z $1 ]]; then
  usage
fi
gradeFolder=$(parseArgs $1)


# discard switches; keep file arguments
if [[ $1 =~ "^--.*" ]]; then
  fileArgs=(${@:2})
else
  fileArgs=($@)
fi


# print usage instructions when run from platypus 
if [[ ${#fileArgs} -lt 1 ]]; then
  printf "=================================================
INSERT FILES FOR GRADE $gradeFolder STUDENTS ONLY
=================================================\n\n"
  usage
fi

# sentry file that indicates this is the proper Shared drive
# if file is missing, bail out
sentryFile="sentryFile_DO_NOT_REMOVE.txt"
# check for sentry file on shared drive
echo checking sentry file
checkSentry

# set temp directory for cache
myTempDir=$TMPDIR${myLongName}
driveCache=$myTempDir/sharedDriveCache.txt

# cache the files on the shared drive for faster searching
cacheDirs

insertFiles $fileArgs


