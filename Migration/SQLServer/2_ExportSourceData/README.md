# **Module 2_ExportSourceData** (using BCP)

Use Module **2_ExportSourceData** to export data using BCP for specified tables into delimited text files (.csv or .txt). 

You need to run **ExportSourceData.ps1** PowerShell script which will prompt you for the names of two configuration files:

(1)  sql_bcp.json: This simple file specifies the fully qualified SQL server name, type of security, and [bcp](https://docs.microsoft.com/en-us/sql/tools/bcp-utility?view=sql-server-ver15) installation directory. This utility comes with SQL server, you just need to locate where it is. 

(2)  ExportTablesCofig.csv: You can use “GenerateTablesConfig.sql.sql” (in Utilities folder) to automatically generate an initial configuration file with little needs of manual editing. A sample file is provided for you for reference. 

The definition and sample values for each row of the **sql_bcp.json** file s described in below table:

| Parameter Name      | Description                                   | Values (Sample)                                              |
| ------------------- | --------------------------------------------- | ------------------------------------------------------------ |
| ServerName          | Fully qualified SQL Server Name               | .\\YourSQLServerName  or YourSqlServerName or Fully Qualified  Server name |
| ServerType          | Type of the Server: SQL                       | SQL                                                          |
| IntegratedSecurity  | YES or NO for Integrated Security             | YES, NO                                                      |
| OutputFolder        | Folder Name output table data  will be stored | C:\\migratemaster\\output\\2_ExportSourceData                |
| OutputFileExtension | File extension for the table  data output     | .csv or .txt                                                 |
| BcpLocation         | Location of the BCP utility  installed.       | C:\\Program Files\\Microsoft SQL  Server\\Client SDK\\ODBC\\130\\Tools\\Binn |

In the subfolder “**Utilities**”, there is a T-SQL script file “**GenerateExportTablesConfig.sql”** to help you to produce output you can copy and paste (with header) into a .csv file, save it as “ExportTablesConfig.csv”. 

