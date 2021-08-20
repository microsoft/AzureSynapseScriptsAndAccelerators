-- Query for: 22. Object Counts

SELECT DatabaseName,
		CASE TableKind
		when 'A' then 'Aggregate function'
		when 'B' then 'Combined aggregate and ordered analytical function'
		when 'C' then 'Table operator parser contract function'
		when 'D' then 'JAR'
		when 'E' then 'External stored procedure'
		when 'F' then 'Standard function'
		when 'G' then 'Trigger'
		when 'H' then 'Instance or constructor method'
		when 'I' then 'Join index' 
		when 'J' then 'Journal'
		when 'K' then 'Foreign server object'
		when 'L' then 'User-defined table operator'
		when 'M' then 'Macro'
		when 'N' then 'Hash index'
		when 'O' then 'Table with no primary index and no partitioning'
		when 'P' then 'Stored procedure'
		when 'Q' then 'Queue table'
		when 'R' then 'Table function'
		when 'S' then 'Ordered analytical function'		
		when 'T' then 'Table'
		when 'U' then 'User-defined data type'
		when 'V' then 'View'
		when 'W' then 'W?'
		when 'X' then 'Authorization' 
		when 'Y' then 'GLOP set'
		when 'Z' then 'UIF'
		when '1' then 'Dataset Schema Object'
		else TableKind || '?'
		END ObjectKind, COUNT(*) ObjectCount
FROM DBC.TablesV
WHERE DatabaseName NOT IN ('console', 'DBC', 'dbcmngr', 'LockLogShredder', 'SQLJ', 'SysAdmin', 'SYSBAR', 'SYSJDBC', 'SYSLIB', 'SYSSPATIAL', 
'SystemFe', 'SYSUDTLIB', 'SYSUIF', 'Sys_Calendar', 'TDQCD', 'TDStats', 'tdwm', 'TD_SERVER_DB', 'TD_SYSFNLIB', 'TD_SYSGPL','TD_SYSXML',
'PDCRAdmin','PDCRCanary1M','PDCRINFO','PDCRSTG','PDCRCanary0M','PDCRCanary2M','PDCRCanary3M','PDCRADM','PDCRAccess','PDCRTPCD','PDCRCanary4M','PDCRDATA','TDMaps')
GROUP BY DatabaseName, TableKind
ORDER BY 1;
    

