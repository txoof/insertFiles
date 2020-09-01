#!/bin/zsh


usage()
{
  echo "usage here"
  exit 2
}

setGradeFolder() {
  local gradeLevel=$1
  local gradeFolders=(00-Preschool 00-Transition 00-zKindergarten 01-Grade 02-Grade 03-Grade 04-Grade 05-Grade 06-Grade 07-Grade 08-Grade 09-Grade 10-Grade 11-Grade 12-Grade)
  local regexp="([0-9]+)"
  local gradeFolder="/"

  [[ $gradeLevel =~ $regexp ]]
  local gradeIndex=$((${match[1]}+3))

  case $gradeLevel in
    ps)
      local gradeFolder=$gradeFolders[1]
      ;;
    tk)
      local gradeFolder=$gradeFolders[2]
      ;;
    kg)
      local gradeFolder=$gradeFolders[3]
      ;;
    1|2|3|4|5|6|7|8|9|10|11|12)
      gradeFolder=$gradeFolders[$gradeIndex]
      ;;
   esac

   echo $gradeFolder

}

checkSentry() {
  #check for a sentry file on shared drive before executing
  if [[ ! -f $myPath/$sentryFile ]]
  then
    printf "FATAL ERROR
Sentry file is missing from $myPath

Check the following :
     * Google File Stream is running and signed in
     * Check the name of the Google Shared Drive
          * expected name: $myPath
     * $sentryFile exists in $myPath

If '$sentryFile' is missing from the Shared drive,
it can be recreated by opening the terminal app typing or pasting in
the following command:

touch \"$myPath/$sentryFile\"

exiting"
    exit 0
  else
    echo "sentry file found"
  fi
}

cacheDirs() {
  # cache directories stored on shared drive
  #echo "creating cache file: $myTempDir"
  if [[ ! -d $myTempDir ]]
  then
    mkdir $myTempDir
  fi

  # create cache file
  find "${myPath}" -maxdepth 2 -type d > $driveCache
}

insertFiles() {
  # insert files into appropriate folders
  local failCopy=()
  local failCache=()
  local failFileName=()
  local success=()

  printf "inserting ${#fileArgs[@]} files into $gradeFolder folder for each student.\n"
  for each in "${fileArgs[@]}"
  do
    local match=()
    local studentDir=''
    # capture 5 or more consecutive digits in supplied filename
    [[ $each =~ "([0-9]{5,})" ]]
    # check that there is something that looks like a student number
    if [[ ${#match[1]} -gt 0 ]]
    then
      local stuNum=${match[1]}
    else
      failFileName+=($each)
      continue
    fi

    # check the cached directories for student numbers
    studentDir=$(eval grep $stuNum $driveCache)
    # check for successsful completion
    if [[ $? -gt 0 ]] 
    then
      failCache+=($each)
      continue
    fi

    # copy the file into the appropriate directory
    cp $each $studentDir/$gradeFolder
    if [[ $? -gt 0 ]]
    then
      failCopy+=($each)
      continue
    fi

    # record success
    success+=($each)
  done
  # print results of successes and failures
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


# MAIN
# set the program name
[[ `basename ${0}` =~ "(^.*)\..*" ]]
myName=${match[1]}
myLongName="com.txoof."$myName
sentryFile='sentryFile_DO_NOT_REMOVE.txt'

while getopts 'p:g:' c; do
  case $c in 
      p)
        myPath="$OPTARG";;
        #echo "the path is $myPath";;
      g)
        gradeLevel="$OPTARG";;
        #echo "the gradelevel is $gradeLevel";;
      h) usage;;
      esac
done
shift $(( OPTIND -1 ))

if [[ ! "$myPath" ]] || [[ ! "$gradeLevel" ]]
then
  echo 'Required options:'
  echo '     -p /path/to/google\ drive/shared\ drive'
  echo '     -g GradeLevel'
  echo 'see $0 -h  for help'
fi

#echo "checking sentry file..."
checkSentry

# set temp directory for cache
myTempDir=$TMPDIR${myLongName}
driveCache=$myTempDir/sharedDriveCache.txt

# cache the files on the shared drive for faster searching
cacheDirs

#for file in "$@"; do
#  echo $file
#done
fileArgs=($@)
gradeFolder=$(setGradeFolder $gradeLevel)
insertFiles $fileArgs
