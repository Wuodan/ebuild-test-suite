#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# common functions to inherit

die()
{
	echo "$1" 1>&2
	exit 1
}

# fill list of USE flags
init_use()
{
	USE=`equery --quiet uses $CAT/$PKG | cut -b 2- | tr '\n' ' '` || die "equery uses $CAT/$PKG failed!"
}

# fill list of active USE flags
init_use_active()
{
	USE_ACTIVE=`equery --quiet uses $CAT/$PKG | grep '^\+' | cut -b 2- | tr '\n' ' '` || die "equery uses $CAT/$PKG failed!"
}

# test if use flag is active
use_uses()
{
	local use=`equery --quiet uses $CAT/$PKG | grep -e "^\+$1$"` || die "equery uses $CAT/$PKG failed!"
	if [ $use ]; then
		return 0
	else
		return 1
	fi
}

