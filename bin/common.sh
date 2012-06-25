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

