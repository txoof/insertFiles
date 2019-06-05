#!/bin/zsh
# written by Aaron Ciuffo (aaron.ciuffo@gmail.com)
# https://github.com/txoof/insertFiles

# add test results into Google Drive portfolio folders via google filestream

myLongName='com.txoof.'`basename $0`
myName=`basename "$0"`

curMonth=`date '+%m'`
curYear=`date '+%Y'`

schoolYear() {
  # return the school year string based on the current date
  if [[ $curMonth -ge 1 ]] && [[ $curMonth -le 07 ]]; then
    endYear=$curYear
    startYear=$((curYear-1))
  else
    endYear=$((curYear+1))
    startYear=$curYear
  fi
  echo "SY_$startYear-$endYear"
}

schoolYear


