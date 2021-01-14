select
	objdata.dbname DBName
	,objdata.owner Schema
	,objdata.objtype Object_Type
	,count(objdata.objtype) Object_Count
from
	admin._v_sys_database as db
	left join
		admin._v_sys_object_data as objdata
		on db.objname = objdata.dbname
	left join
		admin._v_sys_object_storage_size as objsize
		on objdata.objid = objsize.tblid
group by
	objdata.dbname,
	objdata.owner,
	objdata.objtype
having
	UPPER(objdata.objtype) in ('TABLE', 'EXTERNAL TABLE', 'PROCEDURE', 'FUNCTION', 'AGGREGATE', 'LIBRARY', 'MATERIALIZED VIEW', 'MVIEW_STORE', 'SEQUENCE', 'VIEW', 'SYNONYM', 'CONSTRAINT')
	AND
	objdata.dbname not in ('SYSTEM')
order by
	objdata.dbname,
	objdata.owner,
	objdata.objtype;