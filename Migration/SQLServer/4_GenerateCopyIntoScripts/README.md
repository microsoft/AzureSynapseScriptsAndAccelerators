# **Module 4_GenerateCopyIntoScripts**

Use module **4_GenerateCopyIntoScripts** to generate ‘Copy Into’ T-SQL Scripts. 

You will need to run PowerShell Script **GenerateCopyIntoScripts.ps1** which will prompt you for the names of two configuration files:

(1)  **csv_mi.json** or **parquet_mi.json** or **orc_mi.json** (for CSV, Parquet, or ORC respectively) that specifies parameters that are relevant to the T-SQL Command “Copy Into”. 

(2)  **TablesConfig.csv** that has the list of tables to be copied into Synapse from Azure Storage. 

The definition and sample values for each parameter of  **csv_mi.json**  are described in below table. Please note that we have provided various sample configuration files for different scenarios. It is coded in the file name. 

| Parameter Name  | Description                                                  | Values (Sample)                                              |
| --------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| StorateType     | Specify type of Azure Storage. “blob” for  Blob Storage, “adls” for Azure Data Lake Store. | blob or adls (case insensitive)                              |
| Credential      | If providing Storage Account key, (IDENTITY=  'Storage Account Key', SECRET='replaceThisWithYourRealKey==').  If Managed Identity, (IDENTITY= 'Managed  Identity') | (IDENTITY= 'Storage  Account Key', SECRET='replaceThisWithYourRealKey==')   or (IDENTITY= 'Managed Identity') |
| AccountName     | Your Azure Storage Account Name (Blob or  Data Lake Store). Get this from your  Azure Storage Overview blade. | YourStorageAccountName                                       |
| Container       | Container Name in Azure Data Lake Store or  Blob Storage.    | migratemaster                                                |
| RootFolder      | Folder Under Container where the data will  be uploaded. If it is blank (white space), data will be loaded under  container | Folder1 or Blank (white space)                               |
| FileType        | CSV or Parquet or orc                                        | CSV or Parquet or orc                                        |
| Compression     | Compression algorithms used.   CSV supports GZIP  Parquet supports GZIP and Snappy  ORC supports DefaultCodec and Snappy.  Zlib is the default compression for ORC | GZIP, Snappy                                                 |
| FieldQuote      | Identifier that is used for Field Quotations.  Needed only if the FileType is CSV. | \"                                                           |
| FieldTerminator | Terminator used for your data fields  (columns). Needed only if the FileType is CSV. | 0x1F                                                         |
| RowTerminator   | Row Terminator. Needed only if the FileType  is CSV.         | 0x1E                                                         |
| Encoding        | UTF8 is the only encoding supported at this  time. Needed only if the FileType is CSV. | UTF8                                                         |
| MaxErrors       | Maximum errors allowed for importing data.  This should be an integer specifies  the maximum number of reject rows allowed in the load before the COPY  operation is canceled. Each row that cannot be imported by the COPY operation  is ignored and counted as one error. If max_errors is not specified, the  default is 0. | 0, 100, 5000                                                 |
| ErrorsFolder    | Folder name under the container where you’d  like errors logged. | Errors                                                       |
| FirstRow        | Line number of the data file to be used as  first row. If no header, use 1, if there is one line as header, use 2. Needed  only if the FileType is CSV. | 1 or 2 or any #                                              |
| SqlFilePath     | Location where you’d like generated output T-SQL Scripts to be  stored. | C:\\migratemaster\\output\\4_GenerageCopyIntoScripts\\DfsMiCsv |

The definition and sample values for each column in **TablesConfig.csv** is described in below table

| Parameter Name  | Description                                                  | Values (Sample)                                              |
| --------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Active          | 1 – Run line,  0 – Skip line.                                | 0 or 1                                                       |
| DatabaseName    | Database Name                                                | AdventureWorksDW2017                                         |
| SchemaName      | SQL Server Schema Name                                       | dbo                                                          |
| TableName       | SQL Server Table Name                                        | DimCustomer                                                  |
| IdentityInsert  | On or OFF. “On” if the table contains  Identity Data Field. “Off” if the table does not contain it. Leave it blank  if the answer is no. | On or Off. If blank or any other values, it  will be equivalent to “Off”. |
| TruncateTable   | Yes if table needs to be truncated before  loading data into it. | Yes or No. Case Insensitive.                                 |
| AsaDatabaseName | Azure Synapse Database Name (SQL Pool DB  Name), this must match your actual DB name. | AsaDbName                                                    |
| AsaSchema       | Azure Synapse Schema Name                                    | dbo_asa, edw                                                 |

In addition, there are two utilities that will help you to jump start the code generation.

(1)  <u>GenerateTablesConfig.sql:</u> T-SQL Scripts that you can run against your SQL server database to produce a starter TablesConfig.csv file. You can change the script to include the actual Azure Synapse database name. 

(2)  <u>SetManagedIdentity.ps1</u>: PowerShell script to help you to set up managed identity. This step is not required if you created your Azure Storage when you created your Azure Synapse workspace or otherwise already set up. 

