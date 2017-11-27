#!/bin/bash

test -d .git || {

echo "run docker-build.sh in project directory"
exit 1

}


GIT_REVISION=$(git log --pretty=format:'%h %cd' -n 1)

VERSION=$(cat version.txt)

echo "${VERSION} ${GIT_REVISION}" > version.txt

docker build -t i-tee .

git checkout version.txt


echo docker login rangeforce.azurecr.io
echo docker tag i-tee rangeforce.azurecr.io/i-tee:latest
echo docker push rangeforce.azurecr.io/i-tee
