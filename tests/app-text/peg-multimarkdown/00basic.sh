#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test an installation of peg-multimarkdown

# variables

# get pkg specific test files
pkg_prepare()
{
	# grab some test files
	wget --quiet http://fletcherpenney.net/multimarkdown/index.txt
	mv index.txt fIndex.txt || tst_error_exit "mv failed"
	wget --quiet http://daringfireball.net/projects/markdown/index.text
	mv index.text dfbIndex.txt || tst_error_exit "mv failed"
	wget --quiet http://daringfireball.net/projects/markdown/syntax.text
	mv syntax.text dfbSyntax.txt || tst_error_exit "mv failed"
	# read list of test files
	TST_FILES=`ls .`
}

# run basic test for pkg
pkg_test()
{
	local tPrg=multimarkdown
	# basic installation
	tst_test_atom "$tPrg -v"
	tst_test_atom "$tPrg -h"
	local formats='html latex memoir beamer odf opml'
	for format in $formats; do
		# single files
		for file in $TST_FILES; do
			tst_test_atom "$tPrg -b -t $format $file"
		done
		tst_clean
		# multiple files
		tst_test_atom "$tPrg -b -t $format `echo $TST_FILES`"
	done
}
