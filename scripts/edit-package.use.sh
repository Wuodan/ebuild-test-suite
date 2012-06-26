#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# outsourced to this script because it's black magic :-)

ROOT=$(dirname `readlink -f $0`)

# source for common functions
source $ROOT/common.sh

# check if running as root
check_sudo

# parse input
[ "$1" != '' ] || die "Missing first parameter: mode"
MODE=$1
[ "$2" != '' ] || die "Missing second parameter: category/package"
CATPKG=$2

# other variables
ESCAPED_CATPKG=`echo "$CATPKG" | sed 's/\//\\\\\//g'`
USEFILE=/etc/portage/package.use
TEMPFILE=$USEFILE.new

# needed for all modes

# act according to mode
case $MODE in
	# comment out all occurences of a package
	"comment-out")
		# simple packages
		sed -i "s/^$ESCAPED_CATPKG[[:space:]]/# \0/g" $USEFILE
		# package version, revisions
		sed -i -r "s/^[<>=]+$ESCAPED_CATPKG-([[:digit:]]+\.?)+(-[[:alnum:]]+)?\*?[[:space:]]/# \0/g" $USEFILE
		exit 0
		;;
	# remove lines with package from package.use
	"remove")
		# simple packages
		grep -v "^$ESCAPED_CATPKG[[:space:]]" $USEFILE > $TEMPFILE
		mv $TEMPFILE $USEFILE
		# package version, revisions
		grep -v -E "^[<>=]+$ESCAPED_CATPKG-([[:digit:]]+\.?)+(-[[:alnum:]]+)?\*?[[:space:]]" $USEFILE > $TEMPFILE
		# sed -i -r "s/^[<>=]+$ESCAPED_CATPKG-([[:digit:]]+\.?)+(-[[:alnum:]]+)?\*?[[:space:]]/# \0/g" /etc/portage/package.use
		exit 0
		;;
	# insert package with version and  use flags to package.use
	"insert")
		[ "$3" != '' ] || die "Missing third parameter: version"
		VERSION=$3
		[ "$4" != '' ] || die "Missing fourth parameter: useflags"
		USEFLAGS=$4
		`echo "=$CATPKG-$VERSION $USEFLAGS" >> $USEFILE`
		exit 0
		;;
	*)
		die "Unknown mode: $MODE"
		;;
esac
