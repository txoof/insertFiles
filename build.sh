#!/bin/zsh
app_name='insert_files'

pushd ./insert_files
jupyter-nbconvert --to python --template python_clean insert_files.ipynb
pipenv run pyinstaller --onefile --noconfirm --clean --add-data insert_files.ini:. --add-data logging_cfg.ini:. --add-data Help.md:. --exclude-module IPython $app_name.py
#pushd ./dist
#tar cvzf  ../../$app_name.tgz ./$app_name
#popd
~/bin/develtools/pycodesign.py insert_files_codesign.ini
popd
