#!/bin/bash
set -e

PRIMARY_TAG=$(echo "$MATRIX_TAGS" | jq -r '.[0]')
IMAGE_URL="docker://${REGISTRY}/${IMAGE_NAME}:${PRIMARY_TAG}"
IMAGE_URL=$(echo "$IMAGE_URL" | tr '[:upper:]' '[:lower:]')

UPSTREAM_SHA=$(curl -sL -H "User-Agent: GitHub-Actions" \
  "https://api.github.com/repos/transmission/transmission/commits/$REF" | jq -r '.sha')

if [ "$UPSTREAM_SHA" == "null" ] || [ -z "$UPSTREAM_SHA" ]; then
  echo "Failed to fetch upstream commit for $REF"
  exit 1
fi

echo "UPSTREAM_SHA=$UPSTREAM_SHA" >> $GITHUB_ENV

IMAGE_BASE=$(echo "${REGISTRY}/${IMAGE_NAME}" | tr '[:upper:]' '[:lower:]')
FULL_TAGS=""
for tag in $(echo "$MATRIX_TAGS" | jq -r '.[]'); do
  FULL_TAGS="${FULL_TAGS}${IMAGE_BASE}:${tag},"
done
echo "tags=${FULL_TAGS%,}" >> $GITHUB_OUTPUT

if ! skopeo inspect "$IMAGE_URL" > image_info.json 2>/dev/null; then
  echo "should_build=true" >> $GITHUB_OUTPUT
  echo "Reason: Image not found in registry."
  exit 0
fi

LOCAL_HASH=$(git log -1 --format=%h -- Containerfile scripts/)

BUILD_REVISION="${UPSTREAM_SHA}-${LOCAL_HASH}"
echo "BUILD_REVISION=$BUILD_REVISION" >> $GITHUB_ENV

IMAGE_SHA=$(jq -r '.Labels["org.opencontainers.image.revision"] // empty' image_info.json)
CREATED=$(jq -r '.Created // empty' image_info.json)

if [ "$IMAGE_SHA" != "$BUILD_REVISION" ]; then
  echo "should_build=true" >> $GITHUB_OUTPUT
  echo "Reason: Build sources or upstream changed ($IMAGE_SHA -> $BUILD_REVISION)."
  exit 0
fi

if [ -n "$CREATED" ]; then
  CREATED_TS=$(date -d "$CREATED" +%s)
  NOW_TS=$(date +%s)
  AGE=$((NOW_TS - CREATED_TS))
  if [ $AGE -gt 604800 ]; then # 7 дней
    echo "should_build=true" >> $GITHUB_OUTPUT
    echo "Reason: Image is older than 7 days."
    exit 0
  fi
fi

echo "should_build=false" >> $GITHUB_OUTPUT
echo "Reason: Image is up to date."
