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
# other variables
PVR=$2
FLAGS=
FLAG_COMBINATIONS=

# source package (and version) specific files
ppc_include()
{
	# source all pkg (and version) scripts
	source_pkg_version $DIR_TEST $CATPKG $PVR || die "Sourcing failed"
}

# loads config for a package version and writes it to a file
# each line holds a combination of use flags
# pkg-specific function "pkg_flags()" is called, so it can modify this config
ppc_flags()
{
	local subscript=$ROOT/scripts/get-pkg-version-info.sh
	FLAGS=`$subscript useflags $CATPKG $PVR` || die "Failure in: $subscript useflags $CATPKG $PVR"
	# skip test flag
	FLAGS=`echo "$FLAGS" | sed 's/^test //' | sed 's/ test//' | sed 's/ test //'`
	# echo "flags for $CATPKG $PVR:"
	# echo "$FLAGS"
	if function_exists 'pkg_flags'; then
		pkg_flags || error "pkg_flags failed for $CATPKG-$PVR"
	else
		echo "Function pkg_flags not defined for $CATPKG-$PVR"
	fi
}

# prepare flag combinations
# pkg-specific function "pkg_flag_combinations()" is called, so it can modify this config
ppc_flag_combinations()
{
	# loop over all possible combinations of use-flags (2^n -1)
	FLAG_COMBINATIONS=
	local i=0
	local listlen=`echo "$FLAGS" | wc -w`
	# 2 power of listlen
	# alternative: `echo "2^$listlen" | bc`
	while [ $i -lt $[2**listlen] ]; do
		local j=0
		for flag in $FLAGS; do
			FLAG_COMBINATIONS+=" "
			if [ $(($i & $[2**j])) -eq 0 ]; then
				FLAG_COMBINATIONS+="-"
			fi
			FLAG_COMBINATIONS+="$flag"
			j=$(($j + 1))
		done
		# append newline
		if [ $i -lt $[2**listlen -1] ]; then
			FLAG_COMBINATIONS+=$'\n'
		fi
		i=$[i+1]
		# echo "###"
		# echo $FLAG_COMBINATIONS
		# echo "###"
	done
	if function_exists 'pkg_flag_combinations'; then
		pkg_flag_combinations || error "pkg_flag_combinations failed for $CATPKG-$PVR"
	else
		echo "Function pkg_flag_combinations not defined for $CATPKG-$PVR"
	fi
}

# write config to file
ppc_write()
{
	# remove config file for this pkg-version
	[ -f $DIR_CONF/$CATPKG/$PVR ] && rm $DIR_CONF/$CATPKG/$PVR
	# write to config file
	echo "$FLAG_COMBINATIONS" >> $DIR_CONF/$CATPKG/$PVR

}

ppc_include
ppc_flags
ppc_flag_combinations
ppc_write
