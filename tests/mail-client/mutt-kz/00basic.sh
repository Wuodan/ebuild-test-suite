#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# remove flags, 2^21 combinations is to much
pkg_flags()
{
	FLAGS=""
}

# add a single line for each flag
pkg_flag_combinations()
{
	local flags=" berkdb crypt debug doc gdbm gnutls gpg idn imap mbox nls notmuch pop qdbm sasl selinux sidebar smime smtp ssl tokyocabinet"
	local flagsmin=${flags// / -}
	for flag in $flags; do
		FLAG_COMBINATIONS+=" ${flagsmin/ -$flag/ $flag}"
		if [ "$flag" != 'tokyocabinet' ];then
			FLAG_COMBINATIONS+=$'\n'
		fi
	done
}
