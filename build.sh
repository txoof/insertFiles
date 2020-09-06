#!/bin/zsh
app_name='insert_files'

pushd ./insert_files
~/bin/develtools/nbconvert $app_name.ipynb
pipenv run pyinstaller $app_name.spec --noconfirm --clean
pushd ./dist
tar cvzf  ../../$app_name.tgz ./$app_name
popd
popd
