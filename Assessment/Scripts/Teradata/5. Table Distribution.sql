-- Query for: 5. Table Distribution

SELECT	d.DatabaseName AS DATABASENAME,	t.tvmname AS TABLENAME,	
MAX(CASE WHEN i.FieldPosition = 1 THEN TRIM(c.FieldName) ELSE '' END) AS DistributionKey 
FROM	dbc.dbase d	
JOIN dbc.tvm t	ON d.databaseid = t.databaseid	
JOIN dbc.tvfields c	ON t.tvmid = c.tableid	
JOIN dbc.Indexes i	ON c.tableid = i.tableid AND c.fieldid = i.fieldid 
WHERE i.IndexNumber = 1 AND UniqueFlag = 'Y' 
AND d.databasename NOT IN ('console', 'DBC', 'dbcmngr', 'LockLogShredder', 'SQLJ', 'SysAdmin', 'SYSBAR', 'SYSJDBC', 'SYSLIB', 'SYSSPATIAL', 
	'SystemFe', 'SYSUDTLIB', 'SYSUIF', 'Sys_Calendar', 'TDQCD', 'TDStats', 'tdwm', 'TD_SERVER_DB', 'TD_SYSFNLIB', 'TD_SYSGPL','TD_SYSXML',
	'PDCRAdmin','PDCRCanary1M','PDCRINFO','PDCRSTG','PDCRCanary0M','PDCRCanary2M','PDCRCanary3M','PDCRADM','PDCRAccess','PDCRTPCD','PDCRCanary4M','PDCRDATA','TDMaps') 
GROUP BY d.DatabaseName,	t.Tvmname ORDER BY 1,2;
    

