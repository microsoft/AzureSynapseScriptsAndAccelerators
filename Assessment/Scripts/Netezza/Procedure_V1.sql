select
	p.database ,
	p.schema ,
	'PROCEDURE' ""ObjectType"",
	p.procedure  ,
	p.proceduresignature ,
	p.returns  ,
	length(p.proceduresource) ""proceduresource_Length""
from admin._v_procedure as p;