#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# outsourced to this script because it's black magic :-)

# requires: app-portage/eix

ROOT=$(dirname `readlink -f $0`)

# source for common functions
source $ROOT/common.sh

# parse input
[ "$1" != '' ] || die "Missing first parameter: mode"
MODE=$1
[ "$2" != '' ] || die "Missing second parameter: category/package"
CATPKG=$2

# needed for all modes
EIX=`eix -l -x -Ae "$CATPKG" | grep -v -E '^[[:space:]]+Installed versions:' || die "Could not get infos from eix for $CATPKG"`
EIX=`echo "$EIX" | sed -r -n '1h;1!H;${;g;s/.*Available versions:\s+(.*)\s+Homepage:\s+.*/\1/g;p;}'` || die "Shouldn't happen"
#remove blank lines
EIX=`echo "$EIX" | grep -vE '^[[:space:]]*$'`
# remove leading things
EIX=`echo "$EIX" | sed -r 's/^\s*\(?(~)?\)?\**\s*//'`

# act according to mode
case $MODE in
	# get all versions of a pkg
	# TODO: better parse function
	# too much black magic in here
	"versions")
		# result are versions
		# remove anything after first space
		EIX=`echo "$EIX" | sed -r 's/\s+.*//'`
		# remove trailing "!"
		EIX=`echo "$EIX" | sed -r 's/\!+.*//'`
		# remove trailing {tbz2} from binary package
		EIX=`echo "$EIX" | sed -r 's/\{.*$//'`
		[ "$EIX" != '' ] || die "Parsing of versions failed!"
		echo "$EIX"
		exit 0
		;;
	# get all use flags of a pkg
	"useflags")
		[ "$3" != '' ] || die "Missing third parameter: package-version"
		VERSION=$3
		# escape string
		# VERSION="`echo "$VERSION" | sed -E 's/[^[:alnum:]_-]/\\\\\0/g'`" # why this needs so many \\\ i dunno!?!
		EIX="`echo "$EIX" | grep -r "^$VERSION[{! ]"`"
		# check if found
		[ "`echo "$EIX" | grep "$VERSION"`" != '' ] || die "Version $VERSION of $CATPKG not found in eix output!"
		# no flags
		if [ "`echo "$EIX" | sed -n '/\[/p'`" == '' ]; then
			FLAGS=''
		# parse flags
		else
			FLAGS=`echo "$EIX" | sed -r "s/.*\[(.+)\].*/\1/"`
			# remove leading "+" on front of flags
			FLAGS=`echo "$FLAGS" | sed -r "s/\+//g"`
		fi
		echo "$FLAGS"
		exit 0
		;;
	*)
		die "Unknown mode: $MODE"
		;;
esac
