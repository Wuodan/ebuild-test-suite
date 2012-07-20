#!/bin/bash
# Author: Stefan Kuhn <woudan@hispeed.ch>

# test fbreader
# for bugs #417043 and #424163

# do not test "-gtk -qt4"
# do not test "gtk qt4"
pkg_flag_combinations()
{
	FLAG_COMBINATIONS=$(echo "$FLAG_COMBINATIONS" | grep -v '\-gtk \-qt4')
	FLAG_COMBINATIONS=$(echo "$FLAG_COMBINATIONS" | grep -Ev ' gtk qt4')
}
