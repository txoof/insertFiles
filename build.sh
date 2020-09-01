#!/bin/zsh
app_name='insert_files'

pushd ./insert_files
pipenv run pyinstaller $app_name.spec --noconfirm --clean
pushd ./dist
tar cvzf  ../../$app_name.tgz ./$app_name
popd
popd
