select
	f.database Database,
	f.schema Schame,
	'FUNCTION' ObjectType,
	f.function ""Function"",
	f.functionsignature ,
	f.returns ,
	f.deterministic ,
	f.fenced ,
	f.version
from
	admin._v_function as f
where
	database <> 'SYSTEM';