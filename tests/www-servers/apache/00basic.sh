#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

MY_FLAGS=
MODULE_CRITICAL=" authn_core authz_core authz_host dir mime unixd"
CRITICAL_FLAGS=${MODULE_CRITICAL// / apache2_modules_}
IUSE_MPMS_FORK="prefork" # disabled itk peruser
IUSE_MPMS_THREAD="event worker"

# DISABLED FLAGS:
# there must be a reason and it must be noted here ;-)
# itk : configure: error: MPM itk is not supported on this platform. (amd64)
# peruser : configure: error: MPM peruser is not supported on this platform. (amd64)
# proxy_scgi: Syntax error on line 145 of /etc/apache2/httpd.conf: Cannot load /usr/lib64/apache2/modules/mod_proxy_scgi.so into server: /usr/lib64/apache2/modules/mod_proxy_scgi.so: undefined symbol: ap_proxy_release_connection
DISABLED_FLAGS=" apache2_mpms_itk apache2_mpms_peruser apache2_modules_proxy_scgi"

DOC_FLAGS=" alias negotiation setenvif"
SSL_FLAGS=" socache_shmcb"
DAV_FLAGS=" dav_fs dav_lock"
FILTER_FLAGS=" deflate ext_filter substitute"
CACHE_FLAGS=" cache_disk file_cache"
LOG_CONFIG_FLAGS=" log_forensic logio"
MIME_FLAGS=" mime_magic"
PROXY_BALANCER_FLAGS=" lbmethod_byrequests lbmethod_bytraffic lbmethod_bybusyness lbmethod_heartbeat"
PROXY_FLAGS="${PROXY_BALANCER_FLAGS} proxy_ajp proxy_balancer proxy_connect proxy_ftp proxy_http proxy_scgi"
SLOTMEM_SHM_FLAGS=" lbmethod_byrequests"
# proxy_balancer needs at least one LBMETHOD
LBMETHOD_BYTRAFFIC_FLAGS=" proxy_balancer"

# remove flags, 2^21 combinations is to much
pkg_flags()
{
	# remove static
	MY_FLAGS=" ${FLAGS/ static / }"
	FLAGS=""
	# remove critical
	for flag in $CRITICAL_FLAGS; do
		MY_FLAGS=${MY_FLAGS/ $flag / }
	done
	# remove disabled
	for flag in $DISABLED_FLAGS; do
		MY_FLAGS=${MY_FLAGS/ $flag / }
	done
	# remove dav
	# for flag in $DAV_FLAGS; do
		# MY_FLAGS=${MY_FLAGS/ $flag / }
	# done
	# remove trailing space
	MY_FLAGS=" `echo ${MY_FLAGS} | sed 's/ $//'`"
}

pkg_flag_combinations()
{
	local flagsmin=${MY_FLAGS// / -}
	local line=

	# append negated disabled flags to critical
	CRITICAL_FLAGS+=" ${DISABLED_FLAGS// / -} "

	# one line with minimum active flags
	line=" ${flagsmin}"
	# append critical flags
	line+=" ${CRITICAL_FLAGS} -static"
	FLAG_COMBINATIONS+="$line"
	FLAG_COMBINATIONS+=$'\n'

	# once with static flag and once without
	local static=
	for (( static=0; static<2; static++)); do
		

		# add a single line for each flag
		for flag in $MY_FLAGS; do
			line=" ${flagsmin/ -$flag/ $flag}"
			# append critical flags
			line+=" ${CRITICAL_FLAGS}"

			# thread MPMS
			for mflag in $IUSE_MPMS_THREAD; do
				if [ "$flag" == "apache2_mpms_$mflag" ]; then
					line=${line/ -threads / threads }
					break
				fi
			done

			# doc depends on these modules
			if [ $flag == doc ]; then
				for mflag in $DOC_FLAGS; do
					line=${line/ -apache2_modules_$mflag / apache2_modules_$mflag }
				done
			fi

			# ssl depends on these modules
			if [ $flag == ssl ]; then
				for mflag in $SSL_FLAGS; do
					line=${line/ -apache2_modules_$mflag / apache2_modules_$mflag }
				done
			fi

			# handle dav flags
			local dflag=dav
			for d in $DAV_FLAGS; do
				if [ "apache2_modules_$d" == $flag ]; then
					line=" ${line/ -apache2_modules_$dflag / apache2_modules_$dflag }"
					line=" ${line/ -apache2_modules_$dflag$/ apache2_modules_$dflag}"
				fi
			done

			# handle filter flags
			local dflag=filter
			for d in $FILTER_FLAGS; do
				if [ "apache2_modules_$d" == $flag ]; then
					line=" ${line/ -apache2_modules_$dflag / apache2_modules_$dflag }"
					line=" ${line/ -apache2_modules_$dflag$/ apache2_modules_$dflag}"
				fi
			done

			# handle cache flags
			local dflag=cache
			for d in $CACHE_FLAGS; do
				if [ "apache2_modules_$d" == $flag ]; then
					line=" ${line/ -apache2_modules_$dflag / apache2_modules_$dflag }"
					line=" ${line/ -apache2_modules_$dflag$/ apache2_modules_$dflag}"
				fi
			done

			# handle log_config flags
			local dflag=log_config
			for d in $LOG_CONFIG_FLAGS; do
				if [ "apache2_modules_$d" == $flag ]; then
					line=" ${line/ -apache2_modules_$dflag / apache2_modules_$dflag }"
					line=" ${line/ -apache2_modules_$dflag$/ apache2_modules_$dflag}"
				fi
			done

			# handle mime flags
			local dflag=mime
			for d in $MIME_FLAGS; do
				if [ "apache2_modules_$d" == $flag ]; then
					line=" ${line/ -apache2_modules_$dflag / apache2_modules_$dflag }"
					line=" ${line/ -apache2_modules_$dflag$/ apache2_modules_$dflag}"
				fi
			done

			# handle proxy flags
			local dflag=proxy
			for d in $PROXY_FLAGS; do
				if [ "apache2_modules_$d" == $flag ]; then
					line=" ${line/ -apache2_modules_$dflag / apache2_modules_$dflag }"
					line=" ${line/ -apache2_modules_$dflag$/ apache2_modules_$dflag}"
				fi
			done

			# handle proxy_balancer flags
			local dflag=proxy_balancer
			for d in $PROXY_BALANCER_FLAGS; do
				if [ "apache2_modules_$d" == $flag ]; then
					line=" ${line/ -apache2_modules_$dflag / apache2_modules_$dflag }"
					line=" ${line/ -apache2_modules_$dflag$/ apache2_modules_$dflag}"
				fi
			done

			# handle slotmem_shm flags
			local dflag=slotmem_shm
			for d in $SLOTMEM_SHM_FLAGS; do
				if [ "apache2_modules_$d" == $flag ]; then
					line=" ${line/ -apache2_modules_$dflag / apache2_modules_$dflag }"
					line=" ${line/ -apache2_modules_$dflag$/ apache2_modules_$dflag}"
				fi
			done

			# handle lbmethod_bytraffic flags
			local dflag=lbmethod_bytraffic
			for d in $SLOTMEM_SHM_FLAGS; do
				if [ "apache2_modules_$d" == $flag ]; then
					line=" ${line/ -apache2_modules_$dflag / apache2_modules_$dflag }"
					line=" ${line/ -apache2_modules_$dflag$/ apache2_modules_$dflag}"
				fi
			done

			# toggle static flag
			if [ $static -eq 0 ]; then
				line+=" static"
			else
				line+=" -static"
			fi

			FLAG_COMBINATIONS+="$line"
			FLAG_COMBINATIONS+=$'\n'
		done

		# one line per MPMS with maximum active flags
		local lastflag="apache2_mpms_${IUSE_MPMS_THREAD##* }"
		for flag in $IUSE_MPMS_FORK $IUSE_MPMS_THREAD; do
			line=" ${MY_FLAGS}"
			# append critical flags
			line+=" ${CRITICAL_FLAGS} "

			# disable all other MPMS
			for mflag in $IUSE_MPMS_FORK $IUSE_MPMS_THREAD; do
				if [ "$flag" != "$mflag" ]; then
					line=${line/ apache2_mpms_$mflag / -apache2_mpms_$mflag }
				fi
			done
			
			# no thread MPMS
			for mflag in $IUSE_MPMS_FORK; do
				if [ "$flag" == "$mflag" ]; then
					line=${line/ threads / -threads }
					break
				fi
			done
		
			# toggle static flag
			if [ $static -eq 0 ]; then
				line+=" static"
			else
				line+=" -static"
			fi
			FLAG_COMBINATIONS+="$line"
			if [ "$flag" != "$lastflag" ]; then
				echo "Adding enter ..."
				FLAG_COMBINATIONS+=$'\n'
			fi
		done
		
		if [ $static -eq 0 ]; then
			FLAG_COMBINATIONS+=$'\n'
		fi
	done
}

pkg_test()
{
	test_atom "/etc/init.d/apache2 restart"
	test_atom "wget localhost"
	if [ "`cat index.html`" != '<html><body><h1>It works!</h1></body></html>' ]; then
		die "index.html check fails"
	fi
	test_atom "rm index.html"
}

pkg_test_ssl()
{
	test_atom "wget --no-check-certificate  https://localhost"
	if [ "`cat index.html`" != '<html><body><h1>It works!</h1></body></html>' ]; then
		die "SSL index.html check fails"
	fi
	test_atom "rm index.html"
}

pkg_stop()
{
	test_atom "/etc/init.d/apache2 stop"
}
