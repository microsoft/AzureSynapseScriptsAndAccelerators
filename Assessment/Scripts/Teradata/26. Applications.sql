-- Query for: 26. Applications

SELECT AppId, COUNT(*) AS Queries FROM pdcrinfo.dbqlogtbl_hst
where StartTime >= CURRENT_TIMESTAMP - INTERVAL '7' DAY 
and StartTime <  CURRENT_TIMESTAMP
GROUP BY AppId;
    

