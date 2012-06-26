#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test an installated package

ROOT=$(dirname `readlink -f $0`)/tests

# source for common functions
source $ROOT/../bin/common.sh

# variables
CATPKG=$1
PVR=$2
DIR=/tmp/ebuild-test-suite/$CATPKG
if [ "$PVR" != '' ]; then
	DIR=$DIR-$PVR
fi
FILES=

# sanity check
if [ "$CATPKG" == '' ]; then
	die "Missing package or category!"
fi
if [ ! -d "$ROOT/$CATPKG" ]; then 
	die "$ROOT/$CATPKG is not a directory!"
fi
if [ "$PVR" != '' ] && [ ! -d "$ROOT/$CATPKG" ]; then
	die "$ROOT/$CATPKG/$PVR is not a directory!"
fi

error()
{
	cleanup
	die "$1"
}

# clean up everything
cleanup()
{
	cd $DIR/.. || die "cd failed"
	rm -rf $DIR || die "rm -rf $DIR failed"
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
	echo "Loading from $dir"
	for script in `ls $dir`; do
		if [ -f $dir/$script ]; then
			source $dir/$script
		fi
	done
}

init()
{
	echo "Work dir is $DIR"
	if [ -e $DIR ]; then
		die "$DIR exists!"
	else
		# call init functions
		mkdir -p $DIR || die "mkdir failed"
		echo "Created work dir"
		cd $DIR || die "cd failed"
		# source all pkg scripts
		source_scripts_from_folder $ROOT/$CATPKG
		if [ "$PVR" != '' ] && [ -d $ROOT/$CATPKG/$PVR ]; then
			source_scripts_from_folder $ROOT/$CATPKG/$PVR
		fi
		# pkg specific init
		# grab some test files
		if function_exists 'pkg_init'; then
			pkg_init || error "pgk_init failed"
		else
			echo "Function pkg_init not defined!"
		fi
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
	if function_exists 'pkg_test'; then
		pkg_test || error "pkg_test failed!"
		clean || error "pkg_clean failed!"
	else
		echo "Function pkg_test not defined!"
	fi
	# fill list of active use flags
	local use_active=`equery --quiet uses $CATPKG | grep '^\+' | cut -b 2- | tr '\n' ' '` || die "equery uses $CATPKG failed!"
	# use flag tests
	for uflag in $use_active; do
		# exclude test flag
		if [ "$flag" != 'test' ]; then
			if [ function_exists 'pkg_test_$uflag' ]; then
				pkg_test_$uflag || error "pkg_test_$uflag failed!"
				clean || error "pkg_clean failed!"
			else
				echo "Function pkg_test_$uflag not defined!"
			fi
		fi
	done

}

init
test
cleanup
