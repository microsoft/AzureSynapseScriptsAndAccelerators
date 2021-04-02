-- Query for: 1. Object Counts

    SELECT type_desc AS TYPE, count(*) AS COUNT FROM sys.objects group by type_desc
    

