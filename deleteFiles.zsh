#!/bin/zsh
# set the shared drive name for the portfolio folder
mySharedDriveName="ASH Student Cumulative Folders"
# the name of the folder(s) that contains all of the cum folders
# this should be relative to mySharedDrive
myCumFolder="Student Cumulative Folders (AKA Student Portfolios)"

# root of Google Shared Drives as provided by FileStream
mySharedRoot="/Volumes/GoogleDrive/Shared drives/"

#####
# Functions

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

deleteFiles() {
  echo preparing to delete files
  # insert files into appropriate folders
  local failFind=()
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
    #cp $each $studentDir/$gradeFolder
    fName=$(basename "$each")
    echo find $studentDir -name "$fName"
    result=$(find $studentDir -name "$fName")
    if [[ $? -gt 0 ]]; then
      failCopy+=($each)
      continue
    fi
    echo RESULT: $result

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




##### 
# Main

# set the program name
[[ `basename ${0}` =~ "(^.*)\..*" ]]
myName=${match[1]}
myLongName="com.txoof."${myName}
mySharedDrive=${mySharedRoot}/${mySharedDriveName}/${myCumFolder}

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

fileArgs=($@)
deleteFiles $fileArgs
