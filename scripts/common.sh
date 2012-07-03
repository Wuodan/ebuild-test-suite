#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# common functions to inherit

die()
{
	echo "$1" 1>&2
	exit 1
}

# check if running as root
check_sudo()
{
	if [[ $EUID -ne 0 ]]; then
	   echo "This script must be run as root" 1>&2
	   exit 1
	fi
}

# test if use flag is active
# unused
# use_uses()
# {
#	local use=`equery --quiet uses $CAT/$PKG | grep -e "^\+$1$"` || die "equery uses $CAT/$PKG failed!"
#	if [ $use ]; then
#		return 0
#	else
#		return 1
#	fi
# }

# check if use flag is acticated
use()
{
	[ "$1" != '' ] || die "Missing parameter: use-flag"
	if [[ " $FLAGS " == *"$1"* ]]; then
		return 0
	else
		return 1
	fi
}

# find out if function is defined or not
# returns 0 if exists and 1 if not
function_exists()
{
	[ "$1" != '' ] || die "Missing parameter: function-name"
	# type $1 &>/dev/null && echo "$1() found." || echo "$1() not found."
	type $1 &>/dev/null && return 0 || return 1
}

# reverses order of lines in input
reverse_lines()
{
	sed -n '1!G;h;$p' $1
}

# source all scripts found in given folder
source_scripts_from_folder()
{
	local dir=$1
	echo "Loading from $dir"
	for script in `ls $dir`; do
		if [ -f $dir/$script ]; then
			source $dir/$script || die "Failure with: source $dir/$script"
		fi
	done
}

# source all scripts for a package and version
source_pkg_version()
{
	[ "$1" != '' ] || die "Missing parameter: folder"
	local dirtest=$1
	[ "$2" != '' ] || die "Missing parameter: category/package"
	local catpkg=$2
	[ "$3" != '' ] || die "Missing parameter: version"
	local pvr=$3
	[ ! -d $dirtest/$catpkg ] && die "Not a folder: $dirtest/$catpkg"
	# source all pkg scripts
	source_scripts_from_folder $dirtest/$catpkg || die "Failure sourcing scripts in $dirtest/$catpkg"
	# source version scripts
	if [ -d $dirtest/$catpkg/$pvr ]; then
		source_scripts_from_folder $dirtest/$catpkg/$pvr || die "Failure sourcing scripts in $dirtest/$catpkg/$pvr"
	fi
}
