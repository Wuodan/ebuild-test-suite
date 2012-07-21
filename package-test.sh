#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test an installated package

ROOT=$(dirname `readlink -f $0`)
DIR_TEST=$ROOT/tests
DIR_CONF=$ROOT/config

# source for common functions
source $ROOT/scripts/common.sh

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
if [ ! -d "$DIR_TEST/$CATPKG" ]; then 
	die "$DIR_TEST/$CATPKG is not a directory!"
fi
if [ "$PVR" != '' ] && [ ! -d "$DIR_TEST/$CATPKG" ]; then
	die "$DIR_TEST/$CATPKG/$PVR is not a directory!"
fi

# fill list of active use flags
FLAGS=`equery --quiet uses =$CATPKG-$PVR | \
	grep '^\+' | cut -b 2- | tr '\n' ' '` || \
	die "equery uses =$CATPKG-$PVR failed!"
# skip test flag
FLAGS=`echo "$FLAGS" | sed 's/^test //' | sed 's/ test//' | sed 's/ test //'`

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

pt_init()
{
	echo "Work dir is $DIR"
	if [ -e $DIR ]; then
		die "$DIR exists!"
	else
		# call init functions
		mkdir -p $DIR || die "mkdir failed"
		echo "Created work dir"
		cd $DIR || die "cd failed"
		# source all pkg (and version) scripts
		source_pkg_version $DIR_TEST $CATPKG $PVR || die "Sourcing failed"
		# pkg specific init
		# grab some test files
		if function_exists 'pkg_init'; then
			pkg_init || error "pgk_init failed"
		# else
			# echo "Function pkg_init not defined!"
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
	$1 1>/dev/null || error "Test atom failed: $1"
}

pt_test()
{
	# basic test
	if function_exists 'pkg_test'; then
		pkg_test || error "pkg_test failed!"
		clean || error "clean failed!"
	# else
		# echo "Function pkg_test not defined!"
	fi
	# use flag tests
	for uflag in $FLAGS; do
		if function_exists "pkg_test_$uflag"; then
			pkg_test_$uflag || error "pkg_test_$uflag failed!"
			clean || error "clean failed!"
		# else
			# echo "Function pkg_test_$uflag not defined!"
		fi
	done
	# stop services, etc
	if function_exists 'pkg_stop'; then
		pkg_stop || error "pkg_stop failed!"
		clean || error "clean failed!"
	# else
		# echo "Function pkg_stop not defined!"
	fi
}

pt_init
pt_test
cleanup
