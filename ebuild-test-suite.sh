#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# source for common functions
source bin/common.sh

# run tests based on scripts in ./tests folder
# 
# packages and versions to test are determined by folder structure in ./tests folder
# Example: ./tests/dev-util/ctags/6.3-r1/
# => all version 6.3-r1 of dev-util/ctags
# Example: ./tests/dev-util/ctags without subfolders
# => all available versions for dev-util/ctags
#
# scripts in ./tests/dev-util/ctags/ are included for all tested versions
# scripts in ./tests/dev-util/ctags/6.3-r1/ only for that version
# versions scripts may override package scripts

# variables
ROOT=$(dirname `readlink -f $0`)/tests
ALL_PKG=
VERSIONS=

# check if run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

comment_pkg()
{
	( [ "$1" != '' ] || [ "$2" != '' ] ) || die "Missing input"
	local cat=$1
	local pkg=$2
	# comment out in package.use and package.accept_keywords
	sed -i "s/^[<>=]*$cat\/$pkg[: ]/# \0/g" /etc/portage/package.use
	# TODO: take care of pkg.accept_keywords.
	# Must be done manually for all versions at the moment
	# sed -i "s/^[<>=]*$cat\/$pkg[: ]/# \0/g" /etc/portage/package.accept_keywords
}

# cleans all installations of tested packages
init()
{
	# clean all existing installations
	for cat in `ls $ROOT/`; do
		[ -d $ROOT/$cat ] || die "Unexpected file in $ROOT/$cat"
		for pkg in `ls $ROOT/$cat`; do
			ALL_PKG+=" $cat/$pkg"
			comment_pkg $cat $pkg
		done
	done
	# depclean all packages
	emerge --depclean -v ${ALL_PKG} || die "initial depclean failed"
}

# get all versions & versions of a pkg
# TODO: better parse function
# too much black magic in here
get_pkg_versions()
{
	[ "$1" != '' ] || die "Missing input"
	# parse from eix output 
	local vers=`eix -l -x -Ae "$catpkg" || die "Shouldn't happen"`
	# eeek, black magic
	# result are versions, optionally prepended by "~"
	vers=`echo "$vers" | sed -r -n '1h;1!H;${;g;s/.*Available versions:\s+(.*)\s+Homepage:\s+.*/\1/g;p;}'` || die "Shouldn't happen"
	# echo "$vers"
	vers=`echo "$vers" | sed -r 's/\s*\(?(~)?\)?\s+(\S+)\s.*/\1\2/'`
	# echo "$vers"
	vers=`echo "$vers" | sed -r 's/(~)?([^9]+)\s/\1\2/'`
	[ "$vers" != '' ] || die "Parsing of versions failed!"
	VERSIONS=$vers
}

filter_versions()
{
	[ "$1" != '' ] || die "Missing input"
	echo $1
	echo '---'
	local vers=
	for v in $1; do
		vers+=`echo ": $VERSIONS :" | sed -r "s/.*(~?$v)/ \1/"`
	done
	echo $vers
}

run(){
	# loop over all packages
	for catpkg in $ALL_PKG; do
		# load all versions
		get_pkg_versions $catpkg
		# version folders present, otherwise use all available versions
		# all subfolders of ./tests/cat/pkg/ are treated as versions
		if [ "`ls -d $ROOT/$catpkg/*`" != '' ]; then
			# filter by comparing lists
			filter_versions `ls -d $ROOT/$catpkg/*/ | xargs -l basename | tr '\n' ' '`
		fi
	done 
}

init
run
