#!/bin/sh
git config user.name "$GIT_CONFIG_NAME"
git config user.email "$GIT_CONFIG_EMAIL"
git remote rm origin
git remote add origin "https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git"
npm run deploy
