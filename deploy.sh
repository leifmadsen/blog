#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

pull () {
    git pull
}

push () {
    git push origin master
}

subtree_pull () {
    git subtree pull --prefix=public git@github.com:leifmadsen/blog.git gh-pages
}

subtree_push () {
    git subtree push --prefix=public git@github.com:leifmadsen/blog.git gh-pages
}

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

# Make sure everything is sane
subtree_pull
pull

# Push source and build repos.
push
subtree_push
pull
subtree_pull
