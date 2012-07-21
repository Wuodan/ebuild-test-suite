#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

MY_FLAGS=
CRITICAL_FLAGS='apache2_modules_authz_host apache2_modules_dir apache2_modules_mime'

# remove flags, 2^21 combinations is to much
pkg_flags()
{
	MY_FLAGS=" ${FLAGS} "
	FLAGS=""
	# remove critical
	for flag in $CRITICAL_FLAGS; do
		MY_FLAGS=${MY_FLAGS/ $flag / }
	done
	# remove trailing space
	MY_FLAGS=" `echo ${MY_FLAGS} | sed 's/ $//'`"
}

# add a single line for each flag
pkg_flag_combinations()
{
	local flagsmin=${MY_FLAGS// / -}
	local lastflag="${MY_FLAGS##* }"
	for flag in $MY_FLAGS; do
		FLAG_COMBINATIONS+=" ${flagsmin/ -$flag/ $flag}"
		# append critical flags
		FLAG_COMBINATIONS+=" ${CRITICAL_FLAGS}"
		if [ "$flag" != "$lastflag" ];then
			FLAG_COMBINATIONS+=$'\n'
		fi
	done
}

pkg_test()
{
	test_atom "/etc/init.d/apache2 restart"
	test_atom "wget 127.0.0.1"
	if [ "`cat index.html`" != '<html><body><h1>It works!</h1></body></html>' ]; then
		die "index.html check fails"
	fi
}
