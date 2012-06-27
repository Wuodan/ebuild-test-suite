#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test an installation of peg-multimarkdown
# specific for version 9999

# remove shortcuts from list of flags
# they are simple and just blow up the number of combinations
pkg_flags()
{
	FLAGS="${FLAGS/shortcuts/}"
}

# add a single line for test of flag "shortcuts"
pkg_flag_combinations()
{
	# newline and flag
	FLAG_COMBINATIONS+=$'\n'
	FLAG_COMBINATIONS+='shortcuts'
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

# run test for use flag "latex"
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

# run test for use flag "perl-conversions"
pkg_test_perl-conversions()
{
	pgk_test_programms 'mmd2XHTML.pl mmd2LaTeX.pl mmd2OPML.pl mmd2ODF.pl'
}
