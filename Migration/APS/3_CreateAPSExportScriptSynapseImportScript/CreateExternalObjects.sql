-- Create a db master key if one does not already exist, using your own password.
CREATE MASTER KEY ENCRYPTION BY PASSWORD='<EnterStrongPasswordHere>';
GO

-- Create a database scoped credential.
--DROP DATABASE SCOPED CREDENTIAL AzureStorageCredential
CREATE DATABASE SCOPED CREDENTIAL AzureStorageCredential WITH IDENTITY = '<storageaccountname>',
    SECRET = '<storageaccountkey>';
GO
	
--DROP EXTERNAL DATA SOURCE AZURE_STAGING_STORAGE
CREATE EXTERNAL DATA SOURCE AZURE_STAGING_STORAGE
WITH 
(  
	CREDENTIAL = AzureStorageCredential,
    TYPE = HADOOP,
    LOCATION = 'wasbs://<containername>@<storageaccountname>.blob.core.windows.net/'
); 
GO

--DROP EXTERNAL FILE FORMAT DelimitedFileFormat 
CREATE EXTERNAL FILE FORMAT DelimitedFileFormat 
WITH 
(   FORMAT_TYPE = DELIMITEDTEXT
,	FORMAT_OPTIONS	(   FIELD_TERMINATOR = '|'
					,	STRING_DELIMITER = ''
					,	DATE_FORMAT		 = 'yyyy-MM-dd HH:mm:ss.fff'
					,	USE_TYPE_DEFAULT = FALSE 
					)
);
GO

CREATE SCHEMA [EXT_<yourschema>]
GO
