#!/bin/bash

set -e
set -x

readonly SOURCE_BRANCH=master
readonly TARGET_BRANCH=gh-pages

if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo "Skipping docs deployment"
    exit 0
fi

readonly REPO="$(git config remote.origin.url)"
readonly SSH_REPO="${REPO/https:\/\/github.com\//git@github.com:}"
readonly SHA=$(git rev-parse --verify HEAD)
readonly TARGET_DIR=doc

git clone $REPO $TARGET_DIR
cd $TARGET_DIR
git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH
git reset .
git clean -df
cd ..

mv $TARGET_DIR/.git .git_target
mix docs
mv .git_target $TARGET_DIR/.git

cd $TARGET_DIR

git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

git add .
git commit -m "Deploy docs to GitHub Pages: ${SHA}" || exit 0

ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in ../deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

# Now that we're all set up, we can push.
git push $SSH_REPO $TARGET_BRANCH
