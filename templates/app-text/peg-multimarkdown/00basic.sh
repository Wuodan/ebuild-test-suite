#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test an installation of peg-multimarkdown

# get pkg specific test files
pkg_init()
{
	# grab some test files
	wget --quiet http://fletcherpenney.net/multimarkdown/index.txt
	mv index.txt fIndex.txt || error "mv failed"
	wget --quiet http://daringfireball.net/projects/markdown/index.text
	mv index.text dfbIndex.txt || error "mv failed"
	wget --quiet http://daringfireball.net/projects/markdown/syntax.text
	mv syntax.text dfbSyntax.txt || error "mv failed"
}

# run basic test for pkg
pkg_test()
{
	local prg=multimarkdown
	# basic installation
	test_atom "$prg -v"
	test_atom "$prg -h"
	local formats='html latex memoir beamer odf opml'
	for format in $formats; do
		# single files
		for file in $FILES; do
			test_atom "$prg -b -t $format $file"
		done
		clean
		# multiple files
		test_atom "$prg -b -t $format `echo $FILES`"
	done
}

# test all supplied programms with all FILES
pgk_test_programms()
{
	[ ! "$1" == '' ] || die "input missing"
	local prgList="$1"
	for prg in $prgList; do
		# single files
		for file in $FILES; do
			test_atom "$prg $file"
		done
		clean
		# multiple files
		test_atom "$prg `echo $FILES`"
	done
}

# run test for use flag "shortcuts"
pkg_test_shortcuts()
{
	pgk_test_programms 'mmd2tex mmd2opml mmd2odf'
}
