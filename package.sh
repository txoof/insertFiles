#!/bin/bash
developmentApp="InsertFiles_development.app"
deployApp="insertFiles.app"
packageName="insertFiles.app.zip"
cp -R $developmentApp $deployApp
zip -r $packageName ./insertFiles.app
git commit -m "refresh distribution package" $packageName
git push
