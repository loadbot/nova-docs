#!/bin/bash

# Function to clone source repository, synchronize changes, and push
clone_sync_push() {
    local source_repo="$1"
    local destination_repo="$2"
    local local_path="$3"
    local repo_name="$4"

    echo "Cloning, syncing, and pushing changes for $repo_name"

    # Clone the source repository
    rm -rf "$local_path"
    git clone --depth=1 "$source_repo" "$local_path"
    cp "./Downloads/auto_commit.sh" "$local_path"

    (
        cd "$local_path" || exit 1
		
		# Add auto_commit.sh to .gitignore	
        if ! grep -q "auto_commit.sh" .gitignore; then
            echo "auto_commit.sh" >> .gitignore
		fi

        # Set the correct remote URL for the destination repository
        git remote set-url origin "$destination_repo"

        # Fetch remote changes
        git fetch origin

        # Stash local changes
        git stash

        # Create a temporary commit without .gitignore changes
        git commit -am "Temporary commit without .gitignore changes"

        # Checkout local master branch
        git checkout master

        # Merge local changes onto the latest remote changes
        git merge origin/master

        # Apply stashed changes back, excluding .gitignore
        git stash apply stash@{0}
        git checkout stash@{0} -- . ":!.gitignore"
        git stash drop stash@{0}

        # Commit changes
        git commit -am "Sync changes from stash"

        # Add auto_commit.sh to track it
        git add -f auto_commit.sh

        # Check if there are changes to commit
        if [[ -n $(git status -s) ]]; then
            # Add all changes
            git add .

            # Commit changes
            git commit -m "Sync changes"

            # Push changes
            git push --force origin master
        else
            echo "No new changes to sync."
        fi
    )
}

# Repository changelog and paths
source_repo_changelog="https://github.com/opnsense/changelog.git"
destination_repo_changelog="https://github.com/getcdn/changelog.git"
local_path_changelog="./Downloads/changelog"

# Repository docs and paths
source_repo_docs="https://github.com/laravel/nova-docs.git"
destination_repo_docs="https://github.com/loadbot/nova-docs.git"
local_path_docs="./Downloads/docs"

# Create the local paths if they don't exist
mkdir -p "$local_path_changelog"
mkdir -p "$local_path_docs"

# Clone, sync, and push changes for each repository
clone_sync_push "$source_repo_changelog" "$destination_repo_changelog" "$local_path_changelog" "changelog"
clone_sync_push "$source_repo_docs" "$destination_repo_docs" "$local_path_docs" "docs"

