-- Query for: 2. Table Row Counts

SELECT 'SELECT ''' || TRIM(databasename) || '.' || TRIM(TABLENAME) ||''' AS TableName, CAST(COUNT(*) AS BIGINT) FROM ' || TRIM(databasename) || '.' || TRIM(TABLENAME) || ';' AS CountQeury
FROM dbc.tablesV WHERE tablekind IN ('T')
AND databasename NOT IN ('console', 'DBC', 'dbcmngr', 'LockLogShredder', 'SQLJ', 'SysAdmin', 'SYSBAR', 'SYSJDBC', 'SYSLIB', 'SYSSPATIAL', 
'SystemFe', 'SYSUDTLIB', 'SYSUIF', 'Sys_Calendar', 'TDQCD', 'TDStats', 'tdwm', 'TD_SERVER_DB', 'TD_SYSFNLIB', 'TD_SYSGPL','TD_SYSXML',
'PDCRAdmin','PDCRCanary1M','PDCRINFO','PDCRSTG','PDCRCanary0M','PDCRCanary2M','PDCRCanary3M','PDCRADM','PDCRAccess','PDCRTPCD','PDCRCanary4M','PDCRDATA','TDMaps');  
    

