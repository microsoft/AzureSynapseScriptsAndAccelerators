-- Query for: 13. Function Ext DDL

SELECT 'show ' || 
	CASE 
		WHEN tablekind = 'F' THEN 'function' 
		WHEN tablekind = 'R' THEN 'function' 
		WHEN tablekind = 'S' THEN 'function' 
	END || ' ' || TRIM(databasename) || '.' || TRIM(TABLENAME) || ';'  AS UDFResult
FROM dbc.tablesV WHERE tablekind IN ('F', 'R', 'S')
AND databasename NOT IN ('console', 'DBC', 'dbcmngr', 'LockLogShredder', 'SQLJ', 'SysAdmin', 'SYSBAR', 'SYSJDBC', 'SYSLIB', 'SYSSPATIAL', 
	'SystemFe', 'SYSUDTLIB', 'SYSUIF', 'Sys_Calendar', 'TDQCD', 'TDStats', 'tdwm', 'TD_SERVER_DB', 'TD_SYSFNLIB', 'TD_SYSGPL','TD_SYSXML',
	'PDCRAdmin','PDCRCanary1M','PDCRINFO','PDCRSTG','PDCRCanary0M','PDCRCanary2M','PDCRCanary3M','PDCRADM','PDCRAccess','PDCRTPCD','PDCRCanary4M','PDCRDATA','TDMaps')
ORDER BY databasename, TABLENAME;
    

