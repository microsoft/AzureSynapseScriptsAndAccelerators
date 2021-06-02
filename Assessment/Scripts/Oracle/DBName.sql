select sys_context('USERENV','INSTANCE_NAME') AS INSTANCE_NAME, 
	GLOBAL_NAME as DBNAME
from global_name;
