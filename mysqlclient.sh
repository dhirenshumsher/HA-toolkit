#!/bin/bash
#
# $Id: mysqlclient.sh 3.2 2016-09-08 13:40:17 cmayer $
#
# trivial command that executes sql for us.  this is intended
# to be invoked from an init script via runuser, so we can log
# output the rows as key-value pairs
#
# Copyright 2016 AppDynamics, Inc
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
cd $(dirname $0)

LOGNAME=mysqlclient.log

# source function libraries
. lib/log.sh
. lib/runuser.sh
. lib/conf.sh
. lib/ha.sh
. lib/password.sh
. lib/sql.sh

terminal=false
if [ -t 0 ] ; then
	terminal=true
fi
mysqlopts=-EB

while getopts ct flag; do
	case $flag in
	t)
		terminal=true
		;;
	c)
		mysqlopts=
		;;
	*)
		echo "usage: $0 <options>"
		echo "    [ -t ] interactive"
		echo "    [ -c ] compatible with controller-sh login-db"
		exit 0
		;;
	esac
done

if $terminal ; then
	$MYSQL -A --host=localhost "${CONNECT[@]}" controller
	exit 0
fi

SQL=/tmp/mysqlclient.$$.sql
RESULT=/tmp/mysqlclient.$$.result

cat > $SQL
$MYSQL $mysqlopts --host=localhost "${CONNECT[@]}" controller 2>> $LOGFILE 1> $RESULT < $SQL

if [ -f $APPD_ROOT/HA/LOG_SQL ] ; then
	echo "mysqlclient: " `date` >> $LOGFILE
	cat $SQLFILE >> $LOGFILE
	echo "result:" >> $LOGFILE
	cat $RESULT >> $LOGFILE
fi

cat $RESULT

rm -f $RESULT $SQL
