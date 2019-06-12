#!/bin/zsh\n
# set the shared drive name for the portfolio folder\n
mySharedDriveName=\"ASH Student Cumulative Folders\"\n
# the name of the folder(s) that contains all of the cum folders\n
# this should be relative to mySharedDrive\n
myCumFolder=\"Student Cumulative Folders (AKA Student Portfolios)\"\n
\n
# root of Google Shared Drives as provided by FileStream\n
mySharedRoot=\"/Volumes/GoogleDrive/Shared drives/\"\n
\n
\n
\n
##################################\n
# Functions\n
schoolYear() {\n
  # return the school year string based on the current date\n
  local curMonth=`date '+%m'`\n
  local curYear=`date '+%Y'`\n
  if [[ $curMonth -ge 1 ]] && [[ $curMonth -le 07 ]]; then\n
    local endYear=$curYear\n
    local startYear=$((curYear-1))\n
  else\n
    endYear=$((curYear+1))\n
    startYear=$curYear\n
  fi\n
  # return string with sy value\n
  echo \"SY$startYear-$endYear\"\n
}\n
\n
usage() {\n
  # usage instructions\n
#  if [[ -z $1 ]]; then\n
    printf \"$myName inserts multiple test files into a Google Shared drive\n
folder based on student numbers\n
\n
command line usage:\n
$myName [--<grade sub-folder>] StudentID-File1 FileN-StudentID\n
$myName [--<grade sub-folder>] /path/to/files/.*\n
\n
Grade Sub Folders: --ps, --tk, --kg, --1..--12\n
\n
EXAMPLE:\n
Insert all PDFs in ~/Downloads/grade3 into 03-Grade sub folders\n
$] $myName --3 ~/Downloads/grade3/*.pdf\n
\n
point and click use: drag multiple documents into this window\n
\n
written by Aaron Ciuffo - aaron.ciuffo@gmail.com\n
updates at: https://github.com/txoof/insertFiles\"\n
  exit 0\n
 # fi\n
}\n
\n
checkSentry() {\n
  # check for sentry file on Google Shared drive\n
  # exit out if sentry file is missing\n
  if [[ ! -f $mySharedRoot/$mySharedDriveName/$sentryFile ]]; then\n
printf \"FATAL ERROR\n
Sentry file is missing from $mySharedDriveName\n
\n
Check the following :\n
     * Google File Stream is running and signed in\n
     * Check the name of the Google Shared Drive\n
          * expected name: $mySharedDriveName\n
     * $sentryFile exists in $mySharedDrive\n
\n
If '$checkFile' is missing from the Shared drive,\n
it can be recreated by opening the terminal app typing the following command:\n
\n
touch \\"$mySharedDrive/$sentryFile\\"\n
\n
exiting\"\n
    exit 0\n
  fi\n
}\n
\n
cacheDirs() {\n
  # cache the directories stored in the shared drive\n
  # create cache directory\n
  if [[ ! -d $myTempDir ]]; then\n
    mkdir $myTempDir\n
  fi\n
\n
  # check for sentry file on shared drive\n
  checkSentry\n
\n
  # create the cache file\n
  find \"${mySharedDrive}\" -maxdepth 2 -type d > $driveCache\n
  if [[ $? -gt 0 ]]; then\n
    echo \"caching of remote directories failed\"\n
    echo \"See $driveCache for more details\"\n
    echo \"exiting\"\n
    exit 1\n
  fi\n
}\n
\n
parseArgs() {\n
\n
  # parse the command line arguments\n
  local argOne=$1\n
  local regexp=\"--([0-9]+)\"\n
  local gradeFolders=(00-Preschool 00-Transition 00-zKindergarten 01-Grade 02-Grade 03-Grade 04-Grade 05-Grade 06-Grade 07-Grade 08-Grade 09-Grade 10-Grade 11-Grade 12-Grade)\n
\n
  # check for an a grade level argument (--ps, --tk, --kg, --1, --12)\n
  [[ $argOne =~ $regexp ]]\n
  local gradeLevel=${match[1]}\n
  local gradeIndex=$((gradeLevel+3))\n
\n
  # check if there are no arguments given\n
  if [[ -z $argOne ]]; then\n
    usage\n
  fi\n
\n
  case $argOne in\n
    --ps)\n
      local gradeFolder=$gradeFolders[1]\n
      ;;\n
    --tk)\n
      local gradeFolder=$gradeFolders[2]\n
      ;;\n
    --kg)\n
      local gradeFolder=$gradeFolders[3]\n
      ;;\n
    --1|--2|--3|--4|--5|--6|--7|--8|--9|--10|--11|--12)\n
      local gradeFolder=$gradeFolders[$gradeIndex]\n
      ;;\n
#    *)\n
#      print \"Unknown option: $argOne\n\n\"\n
#      usage\n
  esac\n
\n
  echo $gradeFolder\n
}\n
\n
execute() {\n
  \"$@\"\n
  local mystat=$?\n
  if [ $mystat -ne 0 ]; then\n
    echo \"error with $1\" >&2\n
  fi\n
  echo $mystat\n
}\n
\n
insertFiles() {\n
  # insert files into appropriate folders\n
  local failCopy=()\n
  local failCache=()\n
  local failFileName=()\n
  local success=()\n
  echo inserting files...\n
  for each in \"${fileArgs[@]}\"\n
  do\n
    local match=()\n
    local studentDir=''\n
    # capture 5 or more consecutive digits in supplied ilename\n
    [[ $each =~ \"([0-9]{5,})\" ]]\n
    # check that there is something that looks like a student number\n
    if [[ ${#match[1]} -gt 0 ]]; then\n
      local stuNum=${match[1]}\n
    else\n
      failFileName+=($each)\n
      continue\n
    fi\n
\n
    # check the cached directories for student numbers\n
    studentDir=$(eval grep $stuNum $driveCache)\n
    # check for successful completion\n
    if [[ $? -gt 0 ]]; then\n
      failCache+=($each)\n
      continue\n
    fi\n
\n
    # copy the file into the appropriate directory\n
    print \"cp $each $studentDir/$gradeFolder\"\n
    if [[ $? -gt 0 ]]; then\n
      failCopy=+($each)\n
      continue\n
    fi\n
\n
    # record each successful insertion here\n
    success+=($each)\n
  done\n
\n
  # print results for failures and successes\n
  # successful insertions\n
  if [[ ${#success[@]} -gt 0 ]]; then\n
    printf \"\nSuccessfully inserted ${#success[@]} of ${#fileArgs[@]} files\n\"\n
  fi\n
\n
  # failed due to filename issue\n
  if [[ ${#failFileName[@]} -gt 0 ]]; then\n
    printf \"\nCould not process the following files - no student number in name:\n\"\n
    printf \"%s\n\" \"${failFileName[@]}\"\n
  fi\n
\n
  # failed due to student not existing in cache/on google drive\n
  if [[ ${#failCache[@]} -gt 0 ]]; then\n
\n
    printf \"\nCould not process following files - students not found on Shared Drive:\n\"\n
    printf \"%s\n\" ${failCache[@]}\n
  fi\n
\n
  # failed due to a copy problem\n
  if [[ ${#failCopy[@]} -gt 0 ]]; then\n
    printf \"\nCould not process following files - error copying:\n\"\n
    printf \"%s\n\" ${failCopy[@]}\n
  fi\n
}\n
\n
##################################\n
# main\n
\n
# set the program  name\n
[[ `basename ${0}` =~ \"(^.*)\..*\" ]]\n
myName=${match[1]}\n
myLongName=\"com.txoof.\"${myName}\n
mySharedDrive=${mySharedRoot}/${mySharedDriveName}/${myCumFolder}\n
\n
# if gradelevel switch is provided, set a sub folder within the student folder\n
gradeFolder=$(parseArgs $1)\n
\n
# discard switches; keep file arguments\n
if [[ $1 =~ \"^--.*\" ]]; then\n
  fileArgs=(${@:2})\n
else\n
  fileArgs=($@)\n
fi\n
\n
# set temp directory for cache\n
myTempDir=$TMPDIR${myLongName}\n
driveCache=$myTempDir/sharedDriveCache.txt\n
# sentry file that indicates this is the proper Shared drive\n
# if file is missing, bail out\n
sentryFile=\"sentryFile_DO_NOT_REMOVE.txt\"\n
\n
# cache the files on the shared drive for faster searching\n
cacheDirs\n
\n
insertFiles $fileArgs\n
\n
\n
