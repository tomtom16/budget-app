#!/bin/bash

set -e

#mvn clean package -DskipTests

#cd budget-rest/target/ || exit 1

REGISTRY="wiensquareacr.azurecr.io"
IMAGE_NAME="budget-app"
VERSION="0.0.1-SNAPSHOT"

pwd
echo "Image Version: ${VERSION}"

#az acr login --name "${REGISTRY}"
#docker buildx build --platform linux/arm64 --push --build-arg "VERSION=${VERSION}" -t "${REGISTRY}/${IMAGE_NAME}:latest" .
docker buildx build --platform linux/arm64 --load --build-arg "VERSION=${VERSION}" -t "${REGISTRY}/${IMAGE_NAME}:latest" .
#docker push "${REGISTRY}/${IMAGE_NAME}" --all-tags

cd - || exit 1
