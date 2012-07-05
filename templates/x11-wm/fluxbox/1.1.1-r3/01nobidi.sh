#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test bidi flag of x11-wm/fluxbox
# for bug #417311

# bidi flag not present on this version
pkg_flags()
{
	FLAGS=""
}

# run basic test for pkg
pkg_test()
{
	bidi_check
	[ $? -eq 2 ] || die "bidi active when it should not"
}
