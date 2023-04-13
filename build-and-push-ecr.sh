#!/usr/bin/env sh
set -e

REGION="us-east-1"
CIRCLE_SHA1=${CIRCLE_SHA1}
LATEST_BUILD=$ECR_URL:${APP_IMAGE_PREFIX}-latest
BRANCH_BUILD=$ECR_URL:${APP_IMAGE_PREFIX}-${CIRCLE_BRANCH}
SHA_BUILD=$ECR_URL:${APP_IMAGE_PREFIX}-${CIRCLE_SHA1}

echo "Building ${APP_IMAGE_PREFIX}:${CIRCLE_SHA1}"

# log docker into ecr using aws cli
$(aws ecr get-login --no-include-email --region $REGION)

# pull the latest image so we can use the cache
docker pull $LATEST_BUILD || true
docker pull $BRANCH_BUILD || true
docker pull $SHA_BUILD || true

# docker build --cache-from ${ECR_URL}:${APP_IMAGE_PREFIX}-latest \
docker build \
  --cache-from $SHA_BUILD \
  --cache-from $LATEST_BUILD \
  -t app -f Dockerfile.test \
  --build-arg BUNDLE_GITHUB__COM="$BUNDLE_GITHUB__COM" \
  --build-arg NPM_AUTH_TOKEN="$NPM_AUTH_TOKEN" \
  .

# push to ecr
docker tag app $SHA_BUILD
docker tag app $BRANCH_BUILD
docker tag app $LATEST_BUILD
docker push $SHA_BUILD
docker push $BRANCH_BUILD
docker push $LATEST_BUILD
