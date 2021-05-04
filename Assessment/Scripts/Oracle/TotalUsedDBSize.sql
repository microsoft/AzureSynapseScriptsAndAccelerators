 SELECT ROUND(SUM (bytes)/1024/1024/1024,2) AS "Used DB Size (GB)",
 ROUND(SUM (bytes)/1024/1024/1024/1024,4) AS "Used DB Size (TB)"
 FROM sys.dba_segments;