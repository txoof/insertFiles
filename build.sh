#!/bin/zsh
app_name='insert_files'
source_path=./insert_files
version_number=$(grep VERSION $source_path/constants.py | sed -nE  's/^VERSION[ ]+=[ ]+(.*)/\1/p' | tr -d \'\")

pushd $source_path
echo "runing nbconvert on $app_name.ipynb"
jupyter-nbconvert --to python --template python_clean $app_name.ipynb
echo "building with pyinstaller"
pipenv run pyinstaller --onefile --noconfirm --clean --add-data insert_files.ini:. --add-data logging_cfg.ini:. --add-data Help.md:. --exclude-module IPython $app_name.py
#pushd ./dist
#tar cvzf  ../../$app_name.tgz ./$app_name
popd
echo "code signing"
~/bin/develtools/pycodesign.py -O $version_number insert_files_codesign.ini
popd
