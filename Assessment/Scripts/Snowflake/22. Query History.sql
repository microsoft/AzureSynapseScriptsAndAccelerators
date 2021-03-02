-- Query for: 22. Query History
select * from table(information_schema.query_history(
    end_time_range_start=>dateadd(d,-6,current_timestamp),
    end_time_range_end=>current_timestamp));

