#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test an installated package

# source for common functions
source bin/common.sh

# variables
ROOT=$(dirname `readlink -f $0`)/tests
CAT=$1
PKG=$2
PVR=$3
DIR=/tmp/ebuild-test-suite/$CAT/$PKG
if [ "$PVR" != '' ]; then
	DIR=$DIR-$PVR
fi
FILES=
USE_ACTIVE=

# sanity check
if [ "$CAT" == '' ] || [ "$PKG" == '' ]; then
	die "Missing package or category!"
fi
if [ ! -d "$ROOT/$CAT/$PKG" ]; then 
	die "$ROOT/$CAT/$PKG is not a directory!"
fi
if [ "$PVR" != '' ] && [ ! -d "$ROOT/$CAT/$PKG" ]; then
	die "$ROOT/$CAT/$PKG/$PVR is not a directory!"
fi

echo "Work dir is $DIR"

error()
{
	cleanup
	die "$1"
}

# clean up everything
cleanup()
{
	cd $DIR || die "cd failed"
	rm $FILES || die  "rm failed"
	cd ..
	rmdir $DIR || die "rmdir failed"
}

# clean up after a test, preserve files in $FILES
clean()
{
	local files=`ls -1 $TSTDIR | grep -vF -e "$FILES"`
	# echo "files: $files"
	if [ "$files" != '' ]; then
		rm $files || die "rm files failed"
	fi
}

source_scripts_from_folder()
{
	local dir=$1
	ls "$dir"
	echo "Loading from $dir"
	for script in `ls $dir`; do
		if [ -f $dir/$script ]; then
			source $dir/$script
		fi
	done
}

init()
{
	if [ -e $DIR ]; then
		die "$DIR exists!"
	else
		# call init functions
		init_use
		mkdir -p $DIR || die "mkdir failed"
		echo "Created work dir"
		cd $DIR || die "cd failed"
		# source all pkg scripts
		source_scripts_from_folder $ROOT/$CAT/$PKG
		if [ "$PVR" != '' ]; then
			source_scripts_from_folder $ROOT/$CAT/$PKG/$PVR
		fi
		# pkg specific init
		# grab some test files
		pkg_init
		cd $DIR || die "cd failed"
		# read list of test files
		FILES=`ls $DIR`
	fi
}

test_atom()
{
	echo "Running test atom: $1"
	# stdout is suppressed
	# TODO: write logs
	# $1 1>/dev/null || error "Test atom failed: $1"
}

test()
{
	# basic test
	type  pkg_test &>/dev/null || error "Function pkg_test not found!"
	pkg_test || error "pkg_test failed!"
	clean || error "pkg_clean failed!"
	# use flag tests
	for uflag in $USE_ACTIVE; do
		# exclude test flag
		if [ "$flag" != 'test' ]; then
			type  pkg_test_$uflag &>/dev/null || error "Function pkg_test_$uflag not found!"
			pkg_test_$uflag || error "pkg_test_$uflag failed!"
			clean || error "pkg_clean failed!"
		fi
	done

}

init
test
cleanup
