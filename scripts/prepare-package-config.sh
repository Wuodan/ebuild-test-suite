#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# outsourced to this script so sourcing test-files does not pollute scope

ROOT=$(dirname `readlink -f $0`)/..
DIR_TEST=$ROOT/tests
DIR_CONF=$ROOT/config

# source for common functions
source $ROOT/scripts/common.sh

# parse input
[ "$1" != '' ] || die "Missing first parameter: category/package"
CATPKG=$1
[ "$2" != '' ] || die "Missing second parameter: version"
PVR=$2
FLAG_COMBINATIONS=

# loads config for a package version and writes it to a file
# each line holds a combination of use flags
# pkg-specific files are sourced before writing, so they can modify this config
ppc_prepare()
{
	local subscript=$ROOT/scripts/get-pkg-version-info.sh
	local useflags=`$subscript useflags $CATPKG $PVR` || die "Failure in: $subscript useflags $CATPKG $PVR"
	# skip test flag
	local useflags=`echo "$useflags" | sed 's/^test //' | sed 's/ test//' | sed 's/ test //'`
	# echo "flags for $CATPKG $PVR:"
	# echo "$useflags"
	# loop over all possible combinations of use-flags (2^n -1)
	local i=0
	local listlen=`echo "$useflags" | wc -w`
	# 2 power of listlen
	# alternative: `echo "2^$listlen" | bc`
	while [ $i -lt $[2**listlen] ]; do
		local runflags=
		local j=0
		for flag in $useflags; do
			runflags+=" "
			if [ $(($i & $[2**j])) -eq 0 ]; then
				runflags+="-"
			fi
			runflags+="$flag"
			j=$(($j + 1))
		done
		FLAG_COMBINATIONS+="$runflags"
		# append newline
		if [ $i -lt $[2**listlen -1]; then
			FLAG_COMBINATIONS+='\n'
		fi
		i=$[i+1]
	done
}

# source package (and version) specific files
# call the pkg-specific function pkg_prepare()
# if it is defined
ppc_include()
{
	# source all pkg scripts
	if [ -d $DIR_TEST/$CATPKG/$PVR ]; then
		source_scripts_from_folder $DIR_TEST/$CATPKG/$PVR
	fi
	if function_exists 'pkg_prepare'; then
		pgk_prepare || error "pkg_prepare failed"
	else
		echo "Function pgk_prepare  not defined!"
	fi
}

# write config to file
ppc_write()
{
	# remove config file for this pkg-version
	[ -f $DIR_CONF/$CATPKG/$PVR ] && rm $DIR_CONF/$CATPKG/$PVR
	# write to config file
	echo "$runflags" >> $DIR_CONF/$CATPKG/$PVR

}

ppc_prepare
ppc_include
ppc_write
