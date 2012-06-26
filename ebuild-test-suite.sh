#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# requires: sys-devel/bc

ROOT=$(dirname `readlink -f $0`)/tests

# source for common functions
source $ROOT/../bin/common.sh

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
ALL_PKG=

# check if running as root
check_sudo

# cleans all installations of tested packages
init()
{
	local subscript=$ROOT/../bin/edit-package.use.sh
	# loop over folder in ./test ...
	for cat in `ls $ROOT/`; do
		[ -d $ROOT/$cat ] || die "Unexpected file in $ROOT/$cat"
		for pkg in `ls $ROOT/$cat`; do
			ALL_PKG+=" $cat/$pkg"
			# comment out in package.use
			$subscript comment-out $cat/$pkg || die "Failure in: $subscript comment-out $catpkg"
		done
	done
	# depclean all packages
	emerge -q --depclean ${ALL_PKG} || die "initial depclean failed"
	# depclean system
	emerge -q --depclean || die "initial depclean system failed"
	revdep-rebuild -q || die "initial revdep-rebuild failed"
}

# install a pkg version with given use flags
install_pkg(){
	( [ "$1" != '' ] || [ "$2" != '' ] ) || die "Missing input"
	local catpkg=$1
	local vers=$2
	local runflags=$3
	local subscript=$ROOT/../bin/edit-package.use.sh
	# set in package.use
	# only insert when use flags are not empty
	if [ "$runflags" != '' ];then
		$subscript insert $catpkg $vers "$runflags" || die "Failure in: $subscript insert $catpkg $vers '$runflags'"
	fi
	echo '**************************'
	echo "Emerging $catpkg version $vers with flags [$runflags]"
	echo '**************************'
	# emerge package-version
	emerge -q =$catpkg-$vers || die "Failure to emerge: emerge =$catpkg-$vers"
	# run tests for current installation
	$ROOT/../package-test.sh $catpkg $vers || die "Test failed for: $ROOT/../package-test.sh $catpkg $vers"
	# depclean the package
	# emerge --depclean =$catpkg-$vers || die "depclean failed"
	# TODO: the above fails with my ebuild
	# either I get the DEPEND/RDEPEND wrong or it is as it is
	# workaround: depclean all tested packages
	emerge -q --depclean ${ALL_PKG} || die "depclean failed"
	# depclean system
	emerge -q --depclean || die "depclean system failed"
	revdep-rebuild -q || die "revdep-rebuild failed"
}

# loop over all possible use flag combinatios
# for a given package version
run_version()
{
	( [ "$1" != '' ] || [ "$2" != '' ] ) || die "Missing input"
	local catpkg=$1
	local vers=$2
	local subscript=$ROOT/../bin/get-pkg-version-info.sh
	local useflags=`$subscript useflags $catpkg $ver || die "Failure in: $subscript useflags $catpkg $ver"`
	# skip test flag
	local useflags=`echo "$useflags" | sed 's/^test //' | sed 's/ test//' | sed 's/ test //'`
	# echo "flags for $catpkg $vers:"
	# echo "$useflags"
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
		install_pkg "$catpkg" "$vers" "$runflags"
		i=`echo "$i+1" | bc`
	done
}

# loop over all packages
# plus loop over all their versions
run(){
	# loop over all packages
	local subscript=$ROOT/../bin/get-pkg-version-info.sh
	local versions=
	for catpkg in $ALL_PKG; do
		# package versions defined in ./tests/cat/pkg/ as subfolders
		for dir in $ROOT/$catpkg/*; do
			if [ -d $dir ]; then
				versions+=" $(basename $dir)"
			fi
		done
		# no versions defined, load all versions
		if [ "$versions" == '' ]; then
			versions=`$subscript versions $catpkg || die "Failure in: $subscript versions $catpkg"`
		fi
		for ver in $versions; do
			run_version $catpkg $ver
		done
	done 
}

init
run
