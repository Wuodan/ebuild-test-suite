#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test an installation of peg-multimarkdown

# variables

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

# run test for use flag "shortcuts"
pkg_test_shortcuts()
{
	local prgList='mmd2tex mmd2opml mmd2odf'
	# loop shortcuts
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

# run test for use flag "perl-conversions"
pkg_test_perl-conversions()
{
	local prgList='mmd2XHTML.pl mmd2LaTeX.pl mmd2OPML.pl mmd2ODF.pl table_cleanup.pl mmd_merge.pl'
	# loop shortcuts
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

# run test for use flag "doc"
pkg_test_doc()
{
	# check for html doc file
	if [ ! -f /usr/share/doc/peg-multimarkdown-9999/html/index.html ]; then
		return 1
	else
		return 0
	fi
}

# run test for use flag "doc"
pkg_test_latex()
{
	# all is done by the sub-package
	# which is installed first, so we can test here
	# count 28 *.tex files
	if [ `ls -1 /usr/share/texmf/tex/latex/peg-multimarkdown-latex-support/*.tex | wc -l` -ne 28 ]; then
		return 1
	else
		return 0
	fi
}
