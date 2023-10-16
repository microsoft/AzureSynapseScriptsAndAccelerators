select
	p.database ,
	p.schema ,
	'PROCEDURE' "ObjectType",
	p.procedure  ,
	p.proceduresignature ,
	p.returns  ,
	length(p.proceduresource) "proceduresource_Length"
from _v_procedure as p;