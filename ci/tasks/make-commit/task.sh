#!/usr/bin/env bash

cat /var/version && echo ""

set -eu
git config --global user.email "$GIT_AUTHOR_EMAIL"
git config --global user.name "$GIT_AUTHOR_NAME"

git clone repo repo-commit

mkdir -p $(dirname repo-commit/"$FILE_DESTINATION_PATH")

cp file-source/"$FILE_SOURCE_PATH" \
	repo-commit/"$FILE_DESTINATION_PATH"
cd repo-commit
if [[ -n $(git status --porcelain) ]]; then
	git add -A
	git commit -m "$COMMIT_MESSAGE" --allow-empty
fi
