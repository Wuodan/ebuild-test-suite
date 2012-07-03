#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test bidi flag of x11-wm/fluxbox
# for bug #417311

# test only bidi flag
pkg_flags()
{
	FLAGS="bidi"
}

bidi_check()
{
	local text=$(fluxbox -i | grep -E '^-?BIDI$') || die "shouldn't happen"
	echo "fluxbox -i | grep -E '^-?BIDI$' ==> $text"
	if [ "$text" == 'BIDI' ]; then
		return 0
	elif [ "$text" == '-BIDI' ]; then
		return 1
	else
		return 2
	fi
}

# run basic test for pkg
pkg_test()
{
	if ! use bidi; then
		bidi_check 
		[ $? -eq 1 ] || die "bidi active when it should not"
	fi
}

# run test for flag bidi
pkg_test_bidi()
{
	bidi_check 
	[ $? -eq 0 ] || die "bidi not active when it should"
}
