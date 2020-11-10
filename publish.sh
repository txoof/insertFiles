#!/bin/zsh
source_path=./insert_files

#publish_tar=insert_files.tgz
publish_pkg=insert_files.pkg

version_number=`grep VERSION $source_path/constants.py | sed -nE  's/^VERSION[ ]+=[ ]+(.*)/\1/p' | tr -d \'\"`


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

pycodesign.py -O $version_number codesign.ini

if [ $? -ne 0 ]: then
  echo codesigning failed, exiting
  exit
fi

git tag -a "$tag" -m "$1"
git commit -m "update tar distribution $1" $publish_pkg
git push origin $tag 
