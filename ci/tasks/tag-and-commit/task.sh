#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

TAG="$(cat tag/version)"

git clone repo repo-commit

FILE_DESTINATION_PATH="repo-commit/$FILE_DESTINATION_PATH"
destination_directory=$(dirname "$FILE_DESTINATION_PATH")

if [ ! -d "$destination_directory" ]; then
  echo "Directory $destination_directory does not exist in repository, creating it..."
  mkdir -p "$destination_directory";
fi;

rm -rf "$FILE_DESTINATION_PATH"
cp -R file-source/"$FILE_SOURCE_PATH" \
   "$FILE_DESTINATION_PATH"
cd repo-commit

git config user.name "$GIT_AUTHOR_NAME"
git config user.email "$GIT_AUTHOR_EMAIL"

if [[ -n $(git status --porcelain) ]]; then
  git add -A
  git commit -m "$COMMIT_MESSAGE -- version $TAG" --allow-empty
  git tag "$TAG"
fi

