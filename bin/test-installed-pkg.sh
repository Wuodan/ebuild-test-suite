#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test an installation of peg-multimarkdown

# variables
TST_PKG=peg-multimarkdown
TST_PKG_CATEGORY=app-text
TST_NAME=test-suite-$TST_PKG
TST_DIR=/tmp/ebuild-tests/$TST_NAME
TST_FILES=
TST_USE=
TST_USE_ACTIVE=

echo "Work dir is $TST_DIR"

tst_error_exit_hard()
{
	echo "$1" 1>&2
	exit 1
}

tst_error_exit()
{
	tst_cleanup
	tst_error_exit_hard "$1"
}

# fill list of USE flags
tst_init_use()
{
	TST_USE=`equery --quiet uses $TST_PKG_CATEGORY/$TST_PKG | cut -b 2- | tr '\n' ' '` || tst_error_exit_hard "equery uses $TST_PKG_CATEGORY/$TST_PKG failed!"
}

# fill list of active USE flags
tst_init_use_active()
{
	TST_USE_ACTIVE=`equery --quiet uses $TST_PKG_CATEGORY/$TST_PKG | grep '^\+' | cut -b 2- | tr '\n' ' '` || tst_error_exit_hard "equery uses $TST_PKG_CATEGORY/$TST_PKG failed!"
}

# test if use flag is active
tst_use_uses()
{
	local use=`equery --quiet uses $TST_PKG_CATEGORY/$TST_PKG | grep -e "^\+$1$"` || tst_error_exit_hard "equery uses $TST_PKG_CATEGORY/$TST_PKG failed!"
	if [ $use ]; then
		return 0
	else
		return 1
	fi
}

# clean up everything
tst_cleanup()
{
	cd $TST_DIR || tst_error_exit_hard "cd failed"
	rm $TST_FILES || tst_error_exit_hard  "rm failed"
	cd ..
	rmdir $TST_DIR || tst_error_exit _hard "rmdir failed"
}

# clean up after a test, preserve files in $TST_FILES
tst_clean()
{
	local files=`ls -1 $TSTDIR | grep -vF -e "$TST_FILES"`
	rm $files || tst_error_exit_hard "rm files failed"
}

tst_prepare()
{
	if [ -e $TST_DIR ]; then
		tst_error_exit_hard "$TST_DIR exists!"
	else
		# call init functions
		tst_init_use
		tst_init_use_active
		mkdir -p $TST_DIR
		echo "Created work dir"
		cd $TST_DIR || tst_error_exit "cd failed"
		# pkg specific prepare
		# grab some test files
		pkg_prepare
	fi
}

tst_test_atom()
{
	echo "Running test atom: $1"
	# stdout is suppressed
	# TODO: write logs
	$1 1>/dev/null || tst_error_exit "Test atom failed: $1"
}

tst_test()
{
	# basic test
	pkg_test || tst_error_exit "pkg_test failed!"
	tst_clean || tst_error_exit "pkg_clean failed!"
	# use flag tests
	for uflag in $TST_USE_ACTIVE; do
		pgk_test_$uflag || tst_error_exit "pkg_test_$uflag failed!"
		tst_clean || tst_error_exit "pkg_clean failed!"
	done

}

tst_prepare
tst_test
tst_cleanup
