#!/bin/zsh
app_name='insert_files'

pushd ./insert_files
~/bin/develtools/nbconvert $app_name.ipynb
#pipenv run pyinstaller $app_name.spec --noconfirm --clean
pipenv run pyinstaller --onefile --noconfirm --clean --add-data insert_files.ini:. --add-data logging_cfg.ini:. --add-data Help.md:. --exclude-module IPython $app_name.py
pushd ./dist
tar cvzf  ../../$app_name.tgz ./$app_name
popd
popd
