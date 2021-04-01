-- Query for: 27. Expensive Queries

SELECT Top 100 l.queryid, AppId, ClientId, TotalIOCount, AMPCPUTime, 
	ParserCPUTime, NumResultRows, StatementType, 
	userName, DefaultDatabase , s.SqlTextInfo
FROM pdcrinfo.dbqlogtbl_hst l
INNER JOIN pdcrinfo.DBQLSqlTbl_Hst s On s.Queryid = l.queryid
WHERE StartTime >= CURRENT_TIMESTAMP - INTERVAL '7' DAY 
AND StartTime < CURRENT_TIMESTAMP
AND StatementType NOT IN ('Commit Work','Flush Query Logging')
ORDER BY AMPCPUTime DESC;
    

