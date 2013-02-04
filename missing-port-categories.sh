#!/bin/sh

QUERYBASE='from ports_active PA WHERE NOT EXISTS (SELECT port_id, category_id from ports_categories PC where PC.port_id = PA.id and PC.category_id = PA.category_id)'
QUERYCOUNT='select count(id)'
QUERYROWS="select id, category_id, name, category, category || '/' || name AS port"
QUERYORDER="ORDER BY category, name"
DB='/usr/local/bin/psql freshports.org'


if [ ! -f config.sh ]
then
	echo "config.sh not found..."
	exit 1
fi

. config.sh

if [ $OFFLINE = 1 ]
then
	exit 0
fi



ROWCOUNT=`${DB} -q --pset t -c "${QUERYCOUNT} ${QUERYBASE}"`
if [ ${ROWCOUNT} -ne 0 ]
then
  echo 'This is a list of ports that do not have entries in the ports_categories table'
  echo 'This can be fixed with this query:'
  echo 'begin;  insert into ports_categories select id, category_id from ports_active PA WHERE NOT EXISTS (SELECT * from ports_categories PC where PC.port_id = PA.id and PC.category_id = PA.category_id);'
  ${DB} -q -c "${QUERYROWS} ${QUERYBASE} ${QUERYORDER}"
fi

#ROWS=`${DB} -e -c "${QUERYCOUNT}"`
#for row in ROWS
#do
#  echo ${ROWS} | grep row
#done