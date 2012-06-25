#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# requires: sys-devel/bc

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
FLAGS=

# check if run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# package.use: comment a pkg
pkg_use_comment()
{
	( [ "$1" != '' ] || [ "$2" != '' ] ) || die "Missing input"
	local cat=$1
	local pkg=$2
	# comment out in package.use
	sed -i "s/^[<>=]*$cat\/$pkg[: ]/# \0/g" /etc/portage/package.use
	# TODO: take care of pkg.accept_keywords.
	# Must be done manually for all versions at the moment
	# sed -i "s/^[<>=]*$cat\/$pkg[: ]/# \0/g" /etc/portage/package.accept_keywords
}

# package.use: define a pkg version with use flags
# nothing inserted if no use flags must be set
pkg_use_define()
{
	( [ "$1" != '' ] || [ "$2" != '' || [ "$3" != '' ] ) || die "Missing input"
	local cat=$1
	local pkg=$2
	local vers=$3
	local runflags=$4
	# only insert when use flags are not empty
	if [ "$runflags" != '' ];then
		echo "$cat/$pkg:$vers $runflags" >> /etc/portage/package.use
	fi
	exit 1
}

# package.use: remove a pkg
pkg_use_remove()
{
	( [ "$1" != '' ] || [ "$2" != '' ] ) || die "Missing input"
	local cat=$1
	local pkg=$2
	# remove from package.use
	cp /etc/portage/package.use /etc/portage/package.use.bak
	grep -v '^[<>=]*$cat\/$pkg[(-([:digit:]+\.?)+ ]' /etc/portage/package.use > /etc/portage/package.use.new
	mv /etc/portage/package.use.new /etc/portage/package.use
}
# cleans all installations of tested packages
init()
{
	# clean all existing installations
	for cat in `ls $ROOT/`; do
		[ -d $ROOT/$cat ] || die "Unexpected file in $ROOT/$cat"
		for pkg in `ls $ROOT/$cat`; do
			ALL_PKG+=" $cat/$pkg"
			pkg_use_comment $cat $pkg
		done
	done
	# depclean all packages
	emerge --depclean -v ${ALL_PKG} || die "initial depclean failed"
}

# get all versions & versions of a pkg
# TODO: better parse function
# too much black magic in here
load_pkg_versions()
{
	[ "$1" != '' ] || die "Missing input"
	local catpkg=$1
	# version folders present, otherwise use all available versions
	# all subfolders of ./tests/cat/pkg/ are treated as versions
	if [ "`find $ROOT/$catpkg/ -maxdepth 1 -mindepth 1 -type d -printf %P\\n`" != '' ]; then
		VERSIONS=`ls -d $ROOT/$catpkg/* | xargs -l basename | tr '\n' ' '`
	# no version folder, load all versions
	else
		# parse from eix output 
		local eix=`eix -l -x -Ae "$catpkg" || die "Shouldn't happen"`
		# eeek, black magic
		# result are versions
		eix=`echo "$eix" | sed -r -n '1h;1!H;${;g;s/.*Available versions:\s+(.*)\s+Homepage:\s+.*/\1/g;p;}'` || die "Shouldn't happen"
		eix=`echo "$eix" | sed -r 's/\s*\(?(~)?\)?\s+(\S+)\s.*/\2/'`
		eix=`echo "$eix" | sed -r 's/([^9]+)\s/\1/'`
		[ "$eix" != '' ] || die "Parsing of versions failed!"
		VERSIONS=$eix
	fi
}

# load all use flags of a pkg
load_version_use()
{
	( [ "$1" != '' ] || [ "$2" != '' ] ) || die "Missing input"
	local catpkg=$1
	local vers=$2
	local eix=`eix -l -x -Ae "$catpkg" || die "Shouldn't happen"`
	# eeek, black magic
	eix=`echo "$eix" | sed -r -n '1h;1!H;${;g;s/.*Available versions:\s+(.*)\s+Homepage:\s+.*/\1/g;p;}'` || die "Shouldn't happen"
	# escape string
	local versEsc="`echo "$vers" | sed -E 's/[^[:alnum:]_-]/\\\\\0/g'`" # why this needs so many \\\ i dunno!?!
	eix="`echo "$eix" | grep -r "[[:space:]]$versEsc[[:space:]]"`"
	# no flags
	if [ "`echo "$eix" | sed -n '/\[/p'`" == '' ]; then
		FLAGS=''
	# parse flags
	else
		FLAGS=`echo "$eix" | sed -r "s/.*\[(.+)\].*/\1/"`
	fi
	# echo "flags for $catpkg $vers:"
	# echo $FLAGS
}

# install a given package version with given use flag combination
run_version_withflags()
{
	( [ "$1" != '' ] || [ "$2" != '' ] ) || die "Missing input"
	local catpkg=$1
	local vers=$2
	local runflags=$3
}

# install a pkg version with given use flags
install_pkg(){
	( [ "$1" != '' ] || [ "$2" != '' || [ "$3" != '' ] ) || die "Missing input"
	local catpkg=$1
	local vers=$2
	local runflags=$3
	local cat=`echo $catpkg |  sed -r 's/\/.*//'`
	local pkg=`echo "$catpkg" | sed -r 's/[^\/]+\///'`
	echo "$cat" "$pkg" "$vers" "$runflags"
	# set in package.use
	pkg_use_define "$cat" "$pkg" "$vers" "$runflags"


	pkg_use_remove "$cat" "$pkg"
}

# loop over all possible use flag combinatios
# for a given package version
run_version()
{
	( [ "$1" != '' ] || [ "$2" != '' ] ) || die "Missing input"
	local catpkg=$1
	local vers=$2
	# skip test flag
	local useflags=`echo "$FLAGS" | sed 's/^test //' | sed 's/ test//' | sed 's/ test //'`
	echo "flags for $catpkg $vers:"
	echo "$useflags"
	# loop over all possible combinations of use-flags (2^n -1)
	local i=0
	local listlen=`echo "$useflags" | wc -w`
	while [ $i -lt `echo "2^$listlen" | bc` ]; do
		local runflags=
		local j=0
		for flag in $useflags; do
			runflags+=" "
			if [ $(($i & `echo "2^$j" | bc` )) -eq 0 ]; then
				runflags+="-"
			fi
			runflags+="$flag"
			j=$(($j + 1))
		done
		i=`echo "$i+1" | bc`
		echo "$runflags"

		install_pkg "$catpkg" "$vers" "$runflags"
	done
}

# loop over all packages
# plus loop over all their versions
run(){
	# loop over all packages
	for catpkg in $ALL_PKG; do
		load_pkg_versions $catpkg
		for ver in $VERSIONS; do
			load_version_use $catpkg $ver
			run_version $catpkg $ver
		done
	done 
}

init
run
