select SYS_CONTEXT ('USERENV','DB_NAME') AS INSTANCE_NAME,
	DBID,
	NAME,
	VERSION AS FEA_VERSION,
	DESCRIPTION
from dba_feature_usage_statistics;