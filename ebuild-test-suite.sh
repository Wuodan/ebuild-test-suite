#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# run tests based on scripts in ./tests folder
# 
# packages and revisions to test are determined by folder structure in ./tests folder
# Example: ./tests/dev-util/ctags/6.3-r1/
# => all revision 6.3-r1 of dev-util/ctags
# Example: ./tests/dev-util/ctags without subfolders
# => all available revisions for dev-util/ctags
#
# scripts in ./tests/dev-util/ctags/ are included for all tested revisions
# scripts in ./tests/dev-util/ctags/6.3-r1/ only for that revision
# revisions scripts may override package scripts

# variables
TST_NAME=`basename $0`
CUR_DIR=`dirname $0`
TST_DIR="/tmp/$TST_NAME"

TST_PKG=
TST_PKG_CATEGORY=
TST_USE=
TST_USE_ACTIVE=


error()
{
	cleanup
	die "$1"
}

clean_pkg()
{
	local cat=$1
	local pkg=$2
	# comment out in package.use and package.accept_keywords
	sed -i "s/^[<>=]*$cat\/$pkg[: ]/# \0/g" /etc/portage/package.use
	sed -i "s/^[<>=]*$cat\/$pkg[: ]/# \0/g" /etc/portage/package.accept_keywords
	# depclean the package
	emerge --depclean -pv $cat/$pkg
}

# cleans all installations
init()
{
	echo "Work dir is $TST_DIR"
	[ ! -e $TST_DIR ] || die "$TST_DIR exists!"
	mkdir -p $TST_DIR
	echo "Created work dir"
	cd $TST_DIR || die_error "cd failed"
	# clean all existing installations
	for cat in `ls $CUR_DIR/tests/`; do
		[ -d $CUR_DIR/tests/$cat ] || die "Unexpected file in $CUR_DIR/tests/$cat"
		for pkg in `ls $CUR_DIR/tests/$cat`; do
			# all folders are treated as revisions
			# [ -d $CUR_DIR/tests/$cat ] || die "Unexpected file in $CUR_DIR/tests/$cat"
		done
	done
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
	
}

tst_run()
{

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
