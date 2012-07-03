#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test bidi flag of x11-wm/fluxbox
# for bug #417311

# run test for flag bidi
pkg_test_bidi()
{
	bidi_check 
	# bidi actication fails for this version, so anything else is unexptected
	[ $? -eq 1 ] || die "WTH? bidi activation should fail and has not or bidi is not present"
}
