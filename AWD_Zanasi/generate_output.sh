#!/usr/bin/env bash
PATH=$1

/usr/bin/cp -rf "/home/archeffect/out/" $PATH
#/usr/bin/cd $PATH
#/ser/bin/cd out
/usr/bin/echo "" > $PATH"/out/.done"
echo "out moved to $PATH"