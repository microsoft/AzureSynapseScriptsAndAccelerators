-- Replace <EnterStrongPasswordHere> with your own password
CREATE MASTER KEY ENCRYPTION BY PASSWORD='<EnterStrongPasswordHere>';
GO

-- Replace <storageaccountname> and <storageaccountkey> with actual values valid in your environment
CREATE DATABASE SCOPED CREDENTIAL AzureStorageCredential WITH IDENTITY = '<storageaccountname>',
    SECRET = '<storageaccountkey>';
GO
	
-- Replace <storageaccountname> and <containername> with actual values valid in your environment
CREATE EXTERNAL DATA SOURCE AZURE_STAGING_STORAGE
WITH 
(  
	CREDENTIAL = AzureStorageCredential,
    TYPE = HADOOP,
    LOCATION = 'wasbs://<containername>@<storageaccountname>.blob.core.windows.net/'
); 
GO

CREATE EXTERNAL FILE FORMAT DelimitedFileFormat 
WITH 
(   FORMAT_TYPE = DELIMITEDTEXT
,	FORMAT_OPTIONS	(   FIELD_TERMINATOR = '0x01'
					,	STRING_DELIMITER = ''
					--	DATE_FORMAT		 = 'yyyy-MM-dd HH:mm:ss.fff'
					,	USE_TYPE_DEFAULT = FALSE 
					)
);
GO

/*
DROP EXTERNAL FILE FORMAT DelimitedFileFormat
GO
DROP DROP EXTERNAL DATA SOURCE AZURE_STAGING_STORAGE
GO
DROP DROP DATABASE SCOPED CREDENTIAL AzureStorageCredential
GO
DROP MASTER KEY
GO
*/
