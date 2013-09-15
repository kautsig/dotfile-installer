#!/bin/bash

# Usage:
# -l symlinks all dotfiles in your home directory
# -u unlink the dotfiles in your home directory
# -f forces replacement of existing files with different content

# config section, but no need to change it
TARGET_DIR=$HOME
DOTFILE_DIR="`pwd`/dotfiles"

# code section
slink=0
ulink=0
force=0

while getopts luf opt
do
    case $opt in
        l) slink=1;;
        u) ulink=1;;
        f) force=1;;
    esac
done

if [[ $slink == 1 ]]
then
    echo "Linking into $TARGET_DIR..."

    # go to dotfile dir to get a list of files to process
    CURRENT_DIR=`pwd`
    cd $DOTFILE_DIR

    # find all files and strip the leading ./
    FILES=`find . -type f | sed "s|^\./||"`
    cd $CURRENT_DIR

    for F in $FILES
    do
        # if the file exists in the home directory check for equality, otherwise just link
        if [[ -f $TARGET_DIR/$F ]]
        then
            H1=`md5sum $HOME/$F | awk '{ print $1 }'`
            H2=`md5sum $DOTFILE_DIR/$F | awk '{ print $1 }'`
            # if the hashes are not equal, only create a symlink if force equals 1
            if [[ $H1 != $H2 && $force -eq 0 ]]
            then
                echo "WARN: Trying to replace file with different content, skipping: $F. Use -f to force replacement."
            else
                rm $TARGET_DIR/$F
                ln -sf $DOTFILE_DIR/$F $TARGET_DIR/$F
            fi
        else
            mkdir -p $TARGET_DIR/`dirname $F`
            ln -s $DOTFILE_DIR/$F $HOME/$F
        fi
    done
fi

if [[ $ulink == 1 ]]
then
    echo "Unlinking from $TARGET_DIR..."
    for F in `find $TARGET_DIR -type l -lname "$DOTFILE_DIR*"`
    do
        cp --remove-destination `readlink $F` $F
    done
fi

echo "Done!"
