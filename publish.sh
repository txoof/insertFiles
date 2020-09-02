#!/bin/zsh
source_path=./insert_files

publish_tar=insert_files.tgz

version_number=`grep version $source_path/constants.py | sed -nE  's/^VERSION[ ]+=[ ]+(.*)/\1/p' | tr -d \'\"`


if [ -z "$1" ]; then
  echo current version number: v$version_number
  echo tar build, tag and push release to github
  echo usage:
  echo $0 \"release comment\"
  exit 0
fi

# run the build script
#./build.sh

tag="v$version_number"

git tag -a "$tag" -m "$1"
git commit -m "update tar distribution $1" $publish_tar
git push origin $tag 
