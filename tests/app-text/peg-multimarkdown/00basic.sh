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

pkg_test_xslt()
{
	for prg in mmd-xslt mmd2tex-xslt; do
		# single files
		for file in $FILES; do
			test_atom "$prg $file"
		done
		clean
		# multiple files do not work with these
	done
	# create 2 opml files with default prg
	multimarkdown -b -t opml fIndex.txt || die "This should not happen"
	multimarkdown -b -t opml dfbIndex.txt || die "This should not happen"
	# now test xslt scripts
	for prg in opml2html opml2mmd opml2tex; do
		# single files
		for file in fIndex.opml dfbIndex.opml; do
			test_atom "$prg $file"
		done
		# multiple files do not work with these
	done
	clean
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

# run test for use flag "perl-conversions"
pkg_test_perl-conversions()
{
	pgk_test_programms 'mmd2XHTML.pl mmd2LaTeX.pl mmd2OPML.pl mmd2ODF.pl'
}
