-- Query for: 29. Daily Query Summary

select      AppId, DefaultDatabase    as "Database",
                        extract (year from StartTime) as "Year",
                        extract (month from StartTime) as "Month",
                        extract (day from StartTime) as "Day",
                        extract (hour from StartTime) as "Hour",
                        sum(case when StatementType = 'Select' then 1 else 0 end) as "Select",
                        sum(case when StatementType = 'Insert' then 1 else 0 end) as "Insert",
                        sum(case when StatementType = 'Update' then 1 else 0 end) as "Update",
                        sum(case when StatementType = 'Delete' then 1 else 0 end) as "Delete",
                        sum(case when StatementType = 'Call' then 1 else 0 end) as "Call",
                        sum(case when StatementType = 'Merge Into' then 1 else 0 end) as "Merge",
                        sum(case when StatementType = 'MLOAD' then 1 else 0 end) as "MLoad",
                        sum(NumResultRows) as "Total Rows"
            from        pdcrinfo.dbqlogtbl_hst
            where       StartTime >= CURRENT_TIMESTAMP - INTERVAL '7' DAY -- '2020-11-01 00:00:00' -- CHANGE AS REQUIRED
                        and StartTime < CURRENT_TIMESTAMP --'2020-11-08 00:00:00' -- CHANGE AS REQUIRED
                        
            group by    AppId, "Database","Year","Month","Day","Hour"
            order by    AppId, "Database","Year","Month","Day","Hour"; 
    

