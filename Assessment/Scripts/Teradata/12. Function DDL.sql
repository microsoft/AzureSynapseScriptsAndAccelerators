-- Query for: 12. Function DDL

SELECT 'show ' || 
	CASE 
		WHEN tablekind = 'A' THEN 'function' 
		WHEN tablekind = 'B' THEN 'function' 
	END || ' ' || TRIM(databasename) || '.' || TRIM(TABLENAME) || ';'  AS UDFResult
FROM dbc.tablesV WHERE tablekind IN ('A', 'B')
AND databasename NOT IN ('console', 'DBC', 'dbcmngr', 'LockLogShredder', 'SQLJ', 'SysAdmin', 'SYSBAR', 'SYSJDBC', 'SYSLIB', 'SYSSPATIAL', 
	'SystemFe', 'SYSUDTLIB', 'SYSUIF', 'Sys_Calendar', 'TDQCD', 'TDStats', 'tdwm', 'TD_SERVER_DB', 'TD_SYSFNLIB', 'TD_SYSGPL','TD_SYSXML',
	'PDCRAdmin','PDCRCanary1M','PDCRINFO','PDCRSTG','PDCRCanary0M','PDCRCanary2M','PDCRCanary3M','PDCRADM','PDCRAccess','PDCRTPCD','PDCRCanary4M','PDCRDATA','TDMaps')
ORDER BY databasename, TABLENAME;
    

