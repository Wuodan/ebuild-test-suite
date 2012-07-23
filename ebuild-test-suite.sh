#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# requires: sys-devel/bc

ROOT=$(dirname `readlink -f $0`)
DIR_TEST=$ROOT/tests
DIR_CONF=$ROOT/config

# source for common functions
source $ROOT/scripts/common.sh

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

# check if running as root
check_sudo

# loop over all package and version
# trigger writing of use-flag combinations to config file
prepare_config()
{
	# echo function $FUNCNAME
	mkdir -p $DIR_CONF
	echo " mkdir -p $DIR_CONF"
	local script_version=$ROOT/scripts/get-pkg-version-info.sh
	local script_config=$ROOT/scripts/prepare-package-config.sh
	local allPkgs=
	# loop over folder in ./test ...
	for cat in `ls $DIR_TEST/`; do
		[ -d $DIR_TEST/$cat ] || die "Unexpected file in $DIR_TEST/$cat"
		for pkg in `ls $DIR_TEST/$cat`; do
			allPkgs+=" $cat/$pkg"
		done
	done
	# save to files
	echo "$allPkgs" > $DIR_CONF/allPkgs.conf
	# loop over all packages and load list of versions
	for catpkg in $allPkgs; do
		# create folder for this pkg
		mkdir -p $DIR_CONF/$catpkg
		local versions=
		# package versions defined in ./tests/cat/pkg/ as subfolders
		for dir in $DIR_TEST/$catpkg/*; do
			if [ -d $dir ]; then
				versions+=" $(basename $dir)"
			fi
		done
		# no versions defined, load all versions
		if [ "$versions" == '' ]; then
			versions=`$script_version versions $catpkg` || die "Failure in: $get-pkg-version-info versions $catpkg"
		fi
		# create config file for every version
		for vers in $versions; do
			$script_config $catpkg $vers || die "Failure in: $prepare-package-config $catpkg $vers"
		done
	done 
}

# if config exists from previous run, then that config is loaded to restart
# otherwise new config is created
prepare()
{
	# echo function $FUNCNAME
	# check for previous config and ask for restart
	local restart='n'
	if [ -d $DIR_CONF ]; then
		read -t 30 -p "Config from previous run found. Do you want to restart (30s timeout) ?(y/N)" restart
		[ "$restart" == 'Y' ] && restart='y'
		[ "$restart" != 'y' ] && rm -rf $DIR_CONF
	fi
	[ "$restart" != 'y' ] && prepare_config
}

# cleans all installations of tested packages
init()
{
	# echo function $FUNCNAME
	local subscript=$ROOT/scripts/edit-package.use.sh
	# load from config file
	local allPkgs="`cat $DIR_CONF/allPkgs.conf`"
	# loop over all packages
	for catpkg in $allPkgs; do
		# echo $catpkg
		# comment out in package.use
		# $subscript comment-out $cat/$pkg || die "Failure in: $subscript comment-out $catpkg"
		# above does not work, try this ...
		$subscript remove $cat/$pkg || die "Failure in: $subscript remove $catpkg"
	done
	# depclean all packages
	echo "Depcleaning tested packages, then depcleaning system ..."
	emerge -q --depclean ${allPkgs} || die "initial depclean failed"
	# depclean system
	emerge -q --depclean || die "initial depclean system failed"
	echo "Running initial revdep-rebuild ..."
	revdep-rebuild -q || die "initial revdep-rebuild failed"
}

# install a pkg version with given use flags
install_pkg()
{
	# echo function $FUNCNAME
	( [ "$1" != '' ] || [ "$2" != '' ] ) || die "Missing input"
	local catpkg=$1
	local vers=$2
	local runflags=$3
	local subscript=$ROOT/scripts/edit-package.use.sh
	# set in package.use
	# only insert when use flags are not empty
	if [ "$runflags" != '' ];then
		$subscript insert $catpkg $vers "$runflags" || die "Failure in: $subscript insert $catpkg $vers '$runflags'"
	fi
	echo '**************************'
	echo "Emerging $catpkg version $vers with flags [$runflags]"
	echo '**************************'
	# emerge package-version using binary packages
	emerge -q --usepkg --binpkg-respect-use y =$catpkg-$vers || die "Failure to emerge: emerge =$catpkg-$vers"
	# run tests for current installation
	$ROOT/package-test.sh $catpkg $vers || die "Test failed for: $ROOT/package-test.sh $catpkg $vers"
}

# depclean after a test-run
run_version_depclean()
{
	# echo function $FUNCNAME
	[ "$1" != '' ] || die "Missing input"
	local allPkgs=$1
	# depclean the package
	# emerge --depclean =$catpkg-$vers || die "depclean failed"
	# TODO: the above fails with my ebuild
	# either I get the DEPEND/RDEPEND wrong or it is as it is
	# workaround: depclean all tested packages
	echo "Depcleaning tested packages, then depcleaning system ..."
	emerge -q --depclean ${allPkgs} || die "depclean failed"
	# depclean system
	emerge -q --depclean || die "depclean system failed"
	echo "Running revdep-rebuild after depclean ..."
	revdep-rebuild -q || die "revdep-rebuild failed"
}

# loop over all defined (possible) use flag combinatios
# for a given package version
run_version()
{
	# echo function $FUNCNAME
	( [ "$1" != '' ] || [ "$2" != '' ] ) || die "Missing input"
	local catpkg=$1
	local vers=$2
	# echo catpkg=$1
	# echo vers=$2
	# load from config files
	local allFlagCombos="`cat $DIR_CONF/$catpkg/$vers`"
	local allPkgs="`cat $DIR_CONF/allPkgs.conf`"
	# echo "allFlagCombos=$allFlagCombos"
	# echo "allPkgs=$allPkgs"
	# special: file empty with no use flags, run once
	if [ "$allFlagCombos" == '' ]; then
		install_pkg "$catpkg" "$vers" "" || die "install_pkg failed"
		run_version_depclean "$allPkgs" || die "run_version_depclean failed"
	else
		echo "$allFlagCombos" | while read runflags; do
			install_pkg "$catpkg" "$vers" "$runflags" || die "install_pkg failed"
			# remove line from config file
			echo "Removing line \"$runflags\" from config file $DIR_CONF/$catpkg/$vers"
			sed -i -r "/$runflags/d" $DIR_CONF/$catpkg/$vers
			run_version_depclean "$allPkgs" || die "run_version_depclean failed"
		done
	fi
	[ $? -eq 0 ] || die "Aborted tests"
	# remove config file
	echo "removing file $DIR_CONF/$catpkg/$vers"
	rm $DIR_CONF/$catpkg/$vers
}

# loop over all packages
# plus loop over their pending versions
run()
{
	# echo function $FUNCNAME
	local subscript=$ROOT/scripts/get-pkg-version-info.sh
	# load from config file
	local allPkgs="`cat $DIR_CONF/allPkgs.conf`"
	for catpkg in $allPkgs; do
		# package versions defined in ./config/cat/pkg/ as files
		local versions="`ls $DIR_CONF/$catpkg/`"
		for vers in $versions; do
			run_version $catpkg $vers || die "run_version failed"
		done
		# remove config folder
		echo "removing folder $DIR_CONF/$catpkg/"
		rmdir $DIR_CONF/$catpkg/
	done
	# remove entire config folder
	echo "Removing config folder"
	rm -rf $DIR_CONF
}

prepare
init
run
