#!/usr/bin/env zsh

# A cleanup script for attachments in my org-mode notes.

ORG_DIR="$HOME/Dropbox/org"
ATTACH_DIR=".attach"
IFS=$'\n'

attachment_dirs() {
    find "$ORG_DIR" -iname "$ATTACH_DIR" -type d
}

attachments_in_dir() {
    cd "$1/../"
    find ".attach" -type f
}

is_orphaned_file() {
    cd "$ORG_DIR"
    ag -Q "$1" >/dev/null
}

if [[ "$1" == "-n" ]]; then
    DRY_RUN=1
    echo "Running dry run!"
fi

for folder in $(attachment_dirs); do
    cd "$folder"
    for file in $(attachments_in_dir "$folder"); do
        if ! is_orphaned_file "$file"; then
            [[ -z "$DRY_RUN" ]] && rm -f "$file"
            echo "Deleted '$file'"
        fi
    done
done
