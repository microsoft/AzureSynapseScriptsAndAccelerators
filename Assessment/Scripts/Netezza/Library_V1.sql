select
	l.schema ,
	'LIBRARY' "ObjectType",
	l.library ,
	coalesce(l.dependencies, 'No Dependencies') dependencies,
	l.automaticload ,
	coalesce(l.description, 'No Description') description
from
	_v_library as l;