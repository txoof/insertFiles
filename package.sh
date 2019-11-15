#!/bin/bash
packageName="insertFiles.app.zip"
zip -r $packageName ./insertFiles.app
git commit -m "refresh distribution package" $packageName
git push
