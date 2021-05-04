select owner as SCHEMA_NAME,
       mview_name,
       container_name,
       query as definition,
       refresh_mode,
       refresh_method,
       build_mode,
       last_refresh_date,
       compile_state
from dba_mviews
order by owner, mview_name;