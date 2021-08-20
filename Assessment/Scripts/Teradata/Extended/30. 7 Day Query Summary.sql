-- Query for: 30. 7 Day Query Summary

select      "Database",
            "Hour",
            avg("Select") as "Select Avg",
            avg("Insert") as "Insert Avg",
            avg("Update") as "Update Avg",
            avg("Delete") as "Delete Avg",
            avg("Call") as "Call Avg",
            avg("Merge") as "Merge Avg",
            avg("MLoad") as "MLoad Avg",
            max("Select") as "Select Max",
            max("Insert") as "Insert Max",
            max("Update") as "Update Max",
            max("Delete") as "Delete Max",
            max("Call") as "Call Max",
            max("Merge") as "Merge Max",
            max("MLoad") as "MLoad Max"
from        (
            select      DefaultDatabase    as "Database",
                        extract (day from StartTime) as "Day",
                        extract (hour from StartTime) as "Hour",
                        sum(case when StatementType = 'Select' then 1 else 0 end) as "Select",
                        sum(case when StatementType = 'Insert' then 1 else 0 end) as "Insert",
                        sum(case when StatementType = 'Update' then 1 else 0 end) as "Update",
                        sum(case when StatementType = 'Delete' then 1 else 0 end) as "Delete",
                        sum(case when StatementType = 'Call' then 1 else 0 end) as "Call",
                        sum(case when StatementType = 'Merge Into' then 1 else 0 end) as "Merge",
                        sum(case when StatementType = 'MLOAD' then 1 else 0 end) as "MLoad"
            from        pdcrinfo.dbqlogtbl_hst
            where       StartTime >= CURRENT_TIMESTAMP - INTERVAL '7' DAY -- '2020-11-01 00:00:00' -- CHANGE CHANGE AS REQUIRED
                        and StartTime < CURRENT_TIMESTAMP --'2020-11-08 00:00:00' -- CHANGE CHANGE AS REQUIRED
                        
            group by    "Database","Day","Hour"
            ) d
group by    "Database","Hour"
order by    "Database","Hour";
    

