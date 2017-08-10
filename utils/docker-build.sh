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

echo docker tag i-tee magavdraakon/i-tee:latest
echo docker login
echo docker push magavdraakon/i-tee

