

--############################################################################################
-- Step 1: Create Master Key for a Database (Required before you can perform step 2)
--############################################################################################
--connect to a particular db 
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'S0meStr0ngKey123';

--############################################################################################
-- Step 2: Create Database Scoped Credential (linked to Azure Blob Storage Account) 
--############################################################################################
-- connect to a particular db


-- Drop DATABASE SCOPED CREDENTIAL yourCredentialName
CREATE DATABASE SCOPED CREDENTIAL yourCredentialName
--Shared Access Signatures cannot be used with PolyBase in SQL Server, APS or Azure Synapse Analytics.
WITH IDENTITY = 'Blob Storage',  
SECRET = 'SampleSampleSampleSampleSampleSample5akd1wpWw==' -- storage account key 


--############################################################################################
-- Step 3: Create External Data Source 
--############################################################################################

CREATE EXTERNAL DATA SOURCE yourExternalDataSourceName WITH (  
    LOCATION ='wasbs://containername@blobaccountname.blob.core.windows.net',  -- replace with actual names
    CREDENTIAL = yourCredentialName, --This name must match the database scoped credential name 
	TYPE = HADOOP
);  


--############################################################################################
-- Step 4: Create External File Format (various format examples )
--############################################################################################
-- connect to a particular db

-- Drop External File Format CsvNoCompression
CREATE EXTERNAL FILE FORMAT CsvNoCompression
WITH (FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS(
          FIELD_TERMINATOR = '0x1F',
          STRING_DELIMITER = '"',
          DATE_FORMAT = '',
          --FIRST_ROW = 1, --This is only available in Synapse. Not in SQL Server 
          USE_TYPE_DEFAULT = False  -- Missing values will be set to Null, instead of default values of the data type
          )
	)

    
-- Drop External File Format CsvDefault
CREATE EXTERNAL FILE FORMAT CsvDefault
WITH (FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS(
          FIELD_TERMINATOR = '0x1F',
          STRING_DELIMITER = '"',
          DATE_FORMAT = '',
          --FIRST_ROW = 1, --This is only available in Synapse. Not in SQL Server 
          USE_TYPE_DEFAULT = False  -- Missing values will be set to Null, instead of default values of the data type
          ),
     DATA_COMPRESSION = 'org.apache.hadoop.io.compress.DefaultCodec'
	)

-- Drop External File Format CsvGzip
CREATE EXTERNAL FILE FORMAT CsvGzip
WITH (FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS(
          FIELD_TERMINATOR = '0x1F',
          STRING_DELIMITER = '"',
          DATE_FORMAT = '',
          --FIRST_ROW = 1, --This is only available in Synapse. Not in SQL Server 
          USE_TYPE_DEFAULT = False  -- Missing values will be set to Null, instead of default values of the data type
          ),
     DATA_COMPRESSION = 'org.apache.hadoop.io.compress.GzipCodec'
	)


-- Drop External File Format ParquetNoCompression
CREATE EXTERNAL FILE FORMAT ParquetNoCompression
WITH (FORMAT_TYPE = PARQUET
	)

      
-- Drop External File Format ParquetGzip
CREATE EXTERNAL FILE FORMAT ParquetGzip
WITH (FORMAT_TYPE = PARQUET,
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.GzipCodec'
	)

    
-- Drop External File Format ParquetSnappy
CREATE EXTERNAL FILE FORMAT ParquetSnappy
WITH (FORMAT_TYPE = PARQUET,
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
	)

