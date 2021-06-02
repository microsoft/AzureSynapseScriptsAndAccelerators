

--############################################################################################
-- Step 1: Create Database Scoped Credential (linked to Azure Blob Storage Account) 
--############################################################################################
--use a Particular DB 
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'S0meStr0ngKey123';

--############################################################################################
-- Step 2: Create Database Scoped Credential (linked to Azure Blob Storage Account) 
--############################################################################################

-- connect to a particular db
-- Create a database scoped credential

-- Drop DATABASE SCOPED CREDENTIAL adls_cr
CREATE DATABASE SCOPED CREDENTIAL yourCredentialName
--Shared Access Signatures cannot be used with PolyBase in SQL Server, APS or Azure Synapse Analytics.
WITH IDENTITY = 'Blob Storage',  
SECRET = 'SampleSampleSampleSampleSampleSample5akd1wpWw==' -- storage account key 


CREATE EXTERNAL DATA SOURCE blob_gailz_ds WITH (  
    LOCATION ='wasbs://containername@blobaccountname.blob.core.windows.net',  -- replace with actual names
    CREDENTIAL = yourCredentialName, --This name must match the database scoped credential name 
	TYPE = HADOOP
);  


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

