select
	a.schema ,
	'AGGREGATE' "ObjectType",
	a.aggregate ,
	a.aggregatesignature ,
	a.returns ,
	a.fenced ,
	a.version
from
	_v_aggregate as a;