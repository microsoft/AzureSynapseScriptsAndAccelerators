select
	objdata.dbname ,
	sum(objsize.used_bytes) / 1024 / 1024 / 1024 / 1024 As TB,
	sum(objsize.used_bytes) / 1024 / 1024 / 1024  as GB,
	sum(objsize.used_bytes) / 1024 / 1024 as MB
from
	_v_sys_object_data as objdata,
	_v_sys_object_storage_size as objsize
where
	objdata.objid = objsize.tblid
group by
	objdata.dbname	
order by
	objdata.dbname,	
	sum(objsize.used_bytes) desc;
select
	objdata.dbname ,
	sum(objsize.used_bytes) / 1024 / 1024 / 1024 / 1024 As TB,
	sum(objsize.used_bytes) / 1024 / 1024 / 1024  as GB,
	sum(objsize.used_bytes) / 1024 / 1024 as MB
from
	_v_sys_object_data as objdata,
	_v_sys_object_storage_size as objsize
where
	objdata.objid = objsize.tblid
group by
	objdata.dbname	
order by
	objdata.dbname,	
	sum(objsize.used_bytes) desc;
