#!/bin/zsh

usage()
{
  echo "usage here"
  exit 2
}

# MAIN
while getopts 'p:g:' c; do
  case $c in 
      p)
        pvalue="$OPTARG"
        echo "the path is $pvalue";;
      g)
        gvalue="$OPTARG"
        echo "the gradelevel is $gvalue";;
      esac
done
shift $(( OPTIND -1 ))

for file in "$@"; do
  echo $file
done

