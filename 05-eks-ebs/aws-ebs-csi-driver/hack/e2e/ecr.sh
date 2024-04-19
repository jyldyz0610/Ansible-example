#!/bin/bash

# Copyright 2023 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

function ecr_build_and_push() {
  REGION=${1}
  AWS_ACCOUNT_ID=${2}
  IMAGE_NAME=${3}
  IMAGE_TAG=${4}
  IMAGE_ARCH=${5}

  # https://docs.aws.amazon.com/AmazonECR/latest/userguide/service-quotas.html
  MAX_IMAGES=10000
  IMAGE_COUNT=$(aws ecr list-images --repository-name ${IMAGE_NAME} --region ${REGION} --query 'length(imageIds[])')

  if [ $IMAGE_COUNT -ge $MAX_IMAGES ]; then
    loudecho "Repository image limit reached. Unable to push new images."
  fi

  loudecho "Building and pushing test driver image to ${IMAGE_NAME}:${IMAGE_TAG}"
  aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

  # Only setup buildx builder on Prow, allow local users to use docker cache
  if [ -n "${PROW_JOB_ID:-}" ]; then
    trap "docker buildx rm ebs-csi-multiarch-builder" EXIT
    docker buildx create --driver-opt=image=moby/buildkit:v0.12.5 --bootstrap --use --name ebs-csi-multiarch-builder
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
  fi

  export IMAGE="${IMAGE_NAME}"
  export TAG="${IMAGE_TAG}"
  if [[ "$WINDOWS" == true ]]; then
    export ALL_OS="linux windows"
    export ALL_OSVERSION_windows="ltsc2022"
    export ALL_ARCH_linux="amd64"
    export ALL_ARCH_windows="${IMAGE_ARCH}"
  else
    export ALL_OS="linux"
    export ALL_ARCH_linux="${IMAGE_ARCH}"
  fi
  make -j $(nproc) all-push
}
