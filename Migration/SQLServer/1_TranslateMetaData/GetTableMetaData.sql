--#======================================================================================================================#
--#                                                                                                                      #
--#  AzureSynapseScriptsAndAccelerators - PowerShell and T-SQL Utilities                                                 #
--#                                                                                                                      #
--#  This utility was developed to aid SMP/MPP migrations to Azure Synapse Migration Practitioners.                      #
--#  It is not an officially supported Microsoft application or tool.                                                    #
--#                                                                                                                      #
--#  The utility and any script outputs are provided on "AS IS" basis and                                                #
--#  there are no warranties, express or implied, including, but not limited to implied warranties of merchantability    #
--#  or fitness for a particular purpose.                                                                                #
--#                                                                                                                      #                    
--#  The utility is therefore not guaranteed to generate perfect code or output. The output needs carefully reviewed.    #
--#                                                                                                                      #
--#                                       USE AT YOUR OWN RISK.                                                          #
--#                                                                                                                      #
--#======================================================================================================================#

WITH Column_List
AS (SELECT ROW_NUMBER() OVER(ORDER BY c.ORDINAL_POSITION) AS FieldID,
			COLUMN_NAME FieldName,
			COLUMN_DEFAULT ColumnDefaultValue,
			dobj.name AS ColumnDefaultName,
			CASE WHEN c.IS_NULLABLE = 'YES' THEN 1 ELSE 0 END IsNullable,
			DATA_TYPE DataType,
			CAST(CHARACTER_MAXIMUM_LENGTH AS INT) MaxLength,
			CAST(NUMERIC_PRECISION AS INT) NumericPrecision,
			CAST(NUMERIC_SCALE AS INT) NumericScale,
			DOMAIN_NAME DomainName,
			CASE WHEN ic.object_id IS NULL THEN 0 ELSE 1 END AS IdentityColumn,
			CAST(ISNULL(ic.seed_value,0) AS INT) AS IdentitySeed,
			CAST(ISNULL(ic.increment_value,0) AS INT) AS IdentityIncrement,
			CASE WHEN st.collation_name IS NOT NULL THEN 1 ELSE 0 END AS IsCharColumn,
			CASE WHEN DATA_TYPE IN ('XML', 'text', 'ntext', 'image', 'hierarchyid', 'sql_variant', 'GEOGRAPHY', 'geometry','timestamp', 'VARBINARY') THEN 1 ELSE 0 END AS IsExclude
	FROM INFORMATION_SCHEMA.COLUMNS c
	JOIN sys.objects s ON c.TABLE_NAME = s.name
	JOIN sys.columns sc ON  s.object_id = sc.object_id AND c.COLUMN_NAME = sc.Name
	LEFT JOIN sys.identity_columns ic ON c.TABLE_NAME = OBJECT_NAME(ic.object_id) AND c.COLUMN_NAME = ic.Name
	JOIN sys.types st ON COALESCE(c.DOMAIN_NAME,c.DATA_TYPE) = st.name
	LEFT OUTER JOIN sys.objects dobj ON dobj.object_id = sc.default_object_id AND dobj.type = 'D'
    WHERE c.TABLE_NAME = '$(TABLENAME)'
	AND s.type = 'U'
	 )
--SELECT CHAR(10) + CASE WHEN IsExclude = 1 THEN '--' ELSE '' END +  /* this line was replaced by below line. Change made by Gail 2020-10-02 
SELECT CHAR(10) + 
CASE WHEN FieldID = (SELECT MIN(FieldID) FROM Column_List) THEN '' ELSE ',' END +
QUOTENAME(FieldName) + ' ' +
        CASE
            WHEN DomainName IS NOT NULL AND 0 = 0 THEN DomainName + CASE WHEN IsNullable = 1 THEN ' NULL ' ELSE ' NOT NULL ' END
            ELSE UPPER(DataType) +
                CASE WHEN (IsCharColumn = 1 AND MaxLength <> -1) OR (IsCharColumn = 0 AND MaxLength <> -1)
				THEN ' (' + CAST(MaxLength AS VARCHAR(10)) + ')' 
				WHEN (IsCharColumn = 1 AND MaxLength = -1) OR (IsCharColumn = 0 AND MaxLength = -1) THEN ' (MAX)'
				WHEN DataType in ('decimal', 'numeric') THEN ' (' + CAST(NumericPrecision AS VARCHAR(10)) + ', ' + CAST(NumericScale AS VARCHAR(10)) + ')'
				WHEN DataType in ('real', 'float') THEN ' (' + CAST(NumericPrecision AS VARCHAR(10)) + ')'
				ELSE '' END +
                CASE WHEN IdentityColumn = 1 THEN ' IDENTITY(' + CAST(IdentitySeed AS VARCHAR(5))+ ',' + CAST(IdentityIncrement AS VARCHAR(5)) + ')' ELSE '' END +
                CASE WHEN IsNullable = 1 THEN ' NULL ' ELSE ' NOT NULL ' END +
                CASE WHEN ColumnDefaultName IS NOT NULL AND 0 = 1 THEN 'CONSTRAINT [' + ColumnDefaultName + '] DEFAULT' + UPPER(ColumnDefaultValue) ELSE '' END
        END + 
        --CASE WHEN FieldID = (SELECT MAX(FieldID) FROM Column_List) THEN '' ELSE ',' END +
		CASE WHEN IsExclude = 1 THEN '--currently not supported in Azure Synapse' ELSE '' END
FROM Column_List 


