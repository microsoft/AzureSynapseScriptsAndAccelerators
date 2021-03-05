select
	a.schema ,
	'AGGREGATE' ""ObjectType"",
	a.aggregate ,
	a.aggregatesignature ,
	a.returns ,
	a.fenced ,
	a.version
from
	admin._v_aggregate as a;