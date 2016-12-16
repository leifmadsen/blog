#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# Makde sure everything is sane
git subtree pull --prefix=public git@github.com:leifmadsen/blog.git gh-pages
git pull

# Build the project.
hugo

# Add changes to git.
git add -A

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git push origin master
git subtree push --prefix=public git@github.com:leifmadsen/blog.git gh-pages
git pull
