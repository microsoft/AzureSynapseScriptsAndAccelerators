-- Query for: 28. Query Log

SELECT TOP 1000 l.queryid, AppId, ClientId, TotalIOCount, AMPCPUTime, 
	ParserCPUTime, NumResultRows, StatementType, 
	userName, DefaultDatabase , s.SqlTextInfo
FROM DBC.DBQLOGTBL l
INNER JOIN DBC.DBQLSQLTBL s On s.Queryid = l.queryid
AND StatementType NOT IN ('Commit Work','Flush Query Logging')
ORDER BY l.Queryid DESC;
    

