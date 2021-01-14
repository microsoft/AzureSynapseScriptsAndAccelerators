select
	objdata.dbname ,
	objdata.schema ,
	objdata.objname ,
	objdata.objtype ,
	sum(objsize.used_bytes) / 1024 / 1024 / 1024 / 1024  as TB,
	sum(objsize.used_bytes) / 1024 / 1024 / 1024 as GB,
	sum(objsize.used_bytes) / 1024 / 1024 as MB
from
	admin._v_sys_object_data as objdata,
	admin._v_sys_object_storage_size as objsize
where
	objdata.objid = objsize.tblid
group by
	objdata.dbname,
	objdata.schema,
	objdata.objname,
	objdata.objtype
order by
	objdata.dbname,
	objdata.schema,
	sum(objsize.used_bytes) desc;