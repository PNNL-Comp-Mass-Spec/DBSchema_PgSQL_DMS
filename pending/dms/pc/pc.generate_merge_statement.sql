--
CREATE OR REPLACE PROCEDURE pc.generate_merge_statement
(
    _tableName text,
    _sourceDatabase text = 'SourceDBName',
    _includeDeleteTest int = 1,
    _includeActionSummary int = 1,
    _includeCreateTableSql int = 1,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Creates a Merge statement for the specified table
**        Does not actually perform the merge, just generates the code required to do so
**        Intended for use when you need to add a merge statement to a stored procedure
**
**        Modeled after code from http://weblogs.sqlteam.com/billg/archive/2011/02/15/generate-merge-statements-FROM-a-table.aspx
**
**  Arguments:
**    _includeCreateTableSql   When _includeActionSummary is non-zero, includes the T-Sql for creating table #Tmp_SummaryOfChanges
**
**  Auth:   mem
**  Date:   10/26/2015 mem - Initial version
**          10/27/2015 mem - Add _includeCreateTableSql
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _newLine varchar(2) := Char(13) + Char(10);
    _primaryKeyColumns TABLE  (ColumnName text NOT NULL, user_type_id int not NULL, IsNumberCol int NOT NULL, IsDateCol int NOT NULL);
    _updatableColumns TABLE  (ColumnName text NOT NULL, user_type_id int not NULL, is_nullable int NOT NULL);
    _insertableColumns TABLE (ColumnName text NOT NULL);
    _types TABLE (user_type_id int not NULL, [IsNumber] int NOT null, [IsDate] int NOT null);
    _tableHasIdentity int := objectproperty(object_id(@tableName), 'TableHasIdentity');
    _list text := '';
    _whereListA text := '';
    _whereListB text := '';
    _continue int := 1;
    _currentColumn text := '';
    _isNumberColumn int;
    _isDateColumn int;
    _insertedList text := '';
    _deletedList text := '';
    _castCharCount varchar(2);
BEGIN
    _tableName := Coalesce(_tableName, '');
    _sourceDatabase := Coalesce(_sourceDatabase, '');
    _includeDeleteTest := Coalesce(_includeDeleteTest, 1);
    _includeActionSummary := Coalesce(_includeActionSummary, 1);
    _includeCreateTableSql := Coalesce(_includeCreateTableSql, 1);
    _message := '';

    If _tableName = '' Then
        _message := '_tableName cannot be empty';
        RAISE INFO '%', _message;
        Return;
    End If;

    If _sourceDatabase = '' Then
        _message := '_sourceDatabase cannot be empty';
        RAISE INFO '%', _message;
        Return;
    End If;

    ---------------------------------------------------
    -- Validate the table name
    ---------------------------------------------------

    If Not Exists (Select * FROM sys.columns WHERE object_id = object_id(_tableName)) Then
        _message := 'Cannot generate a merge statement for ' || _tableName || ': Table not found';
        RAISE INFO '%', _message;
        Return;
    End If;

    ---------------------------------------------------
    -- Populate a table with list of data types that we can compare
    ---------------------------------------------------

    INSERT Into _types Values (36, 0, 0)  -- uniqueidentifier; compatible with Coalesce(ColumnName, '')
    INSERT Into _types Values (167, 0, 0) -- varchar
    INSERT Into _types Values (175, 0, 0) -- char
    INSERT Into _types Values (231, 0, 0) -- nvarchar
    INSERT Into _types Values (239, 0, 0) -- nchar
    INSERT Into _types Values (241, 0, 0) -- XML; Note: cannot be compared using the Coalesce(NULLIF()) test used below

    INSERT Into _types VALUES(40, 0, 1)  -- date
    INSERT Into _types VALUES(41, 0, 1)  -- time
    INSERT Into _types VALUES(42, 0, 1)  -- datetime2
    INSERT Into _types VALUES(58, 0, 1)  -- smalldatetime
    INSERT Into _types VALUES(61, 0, 1)  -- timestamp

    INSERT Into _types Values (48, 1, 0)  -- int
    INSERT Into _types Values (52, 1, 0)  -- int
    INSERT Into _types Values (56, 1, 0)  -- int
    INSERT Into _types Values (59, 1, 0)  -- real
    INSERT Into _types Values (60, 1, 0)  -- money
    INSERT Into _types Values (62, 1, 0)  -- float
    INSERT Into _types Values (104, 1, 0) -- bit
    INSERT Into _types Values (106, 1, 0) -- decimal
    INSERT Into _types Values (108, 1, 0) -- numeric
    INSERT Into _types Values (122, 1, 0) -- smallmoney
    INSERT Into _types Values (127, 1, 0) -- bigint

    ---------------------------------------------------
    -- Include Action Summary statements if specified
    ---------------------------------------------------

    If _includeActionSummary <> 0 Then
        If _includeCreateTableSql <> 0 Then
            RAISE INFO '%', 'Create Table Tmp_SummaryOfChanges (';
            RAISE INFO '%', '    TableName text,';
            RAISE INFO '%', '    UpdateAction text,';
            RAISE INFO '%', '    InsertedKey text,';
            RAISE INFO '%', '    DeletedKey text';
            RAISE INFO '%', ')';
            RAISE INFO '%', '';
            RAISE INFO '%', 'Declare _tableName text';
            RAISE INFO '%', 'Set _tableName = ''' || _tableName || '''';
            RAISE INFO '%', '';
        End If;

        RAISE INFO '%', 'Truncate Table Tmp_SummaryOfChanges';
    End If;

    ---------------------------------------------------
    -- Turn identity insert off for tables with identities
    ---------------------------------------------------

    If _tableHasIdentity = 1 Then
        RAISE INFO '%', 'SET IDENTITY_INSERT [dbo].[' || _tableName || '] ON;'        ;
    End If;

    ---------------------------------------------------
    -- Construct the merge statment
    ---------------------------------------------------

    RAISE INFO '%', '';
    RAISE INFO '%', 'MERGE [dbo].[' || _tableName || '] AS t';
    RAISE INFO '%', 'USING (SELECT * FROM [' || _sourceDatabase || '].[dbo].[' || _tableName || ']) as s';

    -- Lookup the names of the primary key columns
    INSERT INTO _primaryKeyColumns (ColumnName, user_type_id, IsNumberCol, IsDateCol)
    SELECT C.[name],
        C.user_type_id,
        T.[IsNumber],
        T.[IsDate]
    FROM sys.columns C
        INNER JOIN _types T
          ON C.user_type_id = T.user_type_id
        INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk
          ON pk.TABLE_NAME = _tableName AND
              pk.CONSTRAINT_TYPE = 'PRIMARY KEY'
        INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KeyCol
          ON KeyCol.TABLE_NAME = pk.TABLE_NAME AND
              keycol.COLUMN_NAME = C.[name] AND
              KeyCol.CONSTRAINT_NAME = pk.CONSTRAINT_NAME
    WHERE C.object_id = object_id(_tableName)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If Not Exists (Select * From _primaryKeyColumns) Then
        _message := 'Cannot generate a merge statement for ' || _tableName || ' because it does not have a primary key';
        RAISE INFO '%', _message;
        Return;
    End If;

    -- Use the primary key(s) to define the column(s) to join on
    --
    _list := '';

    SELECT @list + 't.[' + ColumnName + '] = s.[' + ColumnName + '] AND ' INTO _list
    FROM _primaryKeyColumns

    -- Remove the trailing "AND"
    --
    SELECT LEFT(@list, LEN(@list) - 4) INTO _list
    RAISE INFO '%', 'ON ( ' || _list || ')';

    -- Find the updatable columns (those that are not primary keys, identity columns, computed columns, or timestamp columns)
    --
    INSERT INTO _updatableColumns (ColumnName, user_type_id, is_nullable)
    SELECT [name], user_type_id, is_nullable
    FROM sys.columns
    WHERE object_id = object_id(_tableName) AND
          [name] NOT IN ( SELECT ColumnName FROM _primaryKeyColumns) AND
          is_identity = 0 AND     -- Identity column
          is_computed = 0 AND     -- Computed column
          user_type_id <> 189     -- Timestamp column
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If Not Exists (Select * from _updatableColumns) Then
        RAISE INFO '%', '-- Note: all of the columns in table ' || _tableName || ' are primary keys or identity columns; there are no updatable columns';
    Else
    -- <UpdateMatchingRows>

        ---------------------------------------------------
        -- Sql for updating when rows match
        -- Do not update primary keys or identity columns
        ---------------------------------------------------
        --
        RAISE INFO '%', 'WHEN MATCHED AND (';

        ---------------------------------------------------
        -- Sql to determine if matched rows have different values
        --
        -- Comparison option #1 (misses edge cases where either value is null and the other is 0)
        --  WHERE ((Coalesce(Source.ColumnA, 0) <> Coalesce(Target.ColumnA, 1))) OR
        --        ((Coalesce(Source.ColumnA, 'BogusNonWordValue12345') <> Coalesce(Target.ColumnA, 'BogusNonWordValue67890')))
        --
        -- Comparison option #2 (contributed by WileCau at http://stackoverflow.com/questions/1075142/how-to-compare-values-which-may-both-be-null-is-t-sql )
        --  NullIf returns Null if the two values are equal, or returns the first value if the fields are not equal
        --  This expression is a bit hard to follow, but it's a compact way to compare two fields to see if they are equal
        --
        --  WHERE Coalesce(NULLIF(Target.Field1, Source.Field1),
        --               NULLIF(Source.Field1, Target.Field1)
        --         ) IS NOT NULL
        ---------------------------------------------------

        -- Compare the non-nullable columns
        --
        SELECT @WhereListA + '    t.[' + [ColumnName] +  '] <> s.[' + [ColumnName] +'] OR' + @newLine INTO _whereListA
        FROM _updatableColumns
        WHERE is_nullable = 0 AND
              user_type_id <> 241   -- Exclude XML columns

        -- Compare the nullable columns
        --
        SELECT @WhereListB + '    Coalesce( NULLIF(t.[' + [ColumnName] +  '], s.[' + [ColumnName] +']),' + @newLine INTO _whereListB
                                         || '            NULLIF(s.[' || [ColumnName] ||'], t.[' || [ColumnName] ||  '])) IS NOT NULL OR' || _newLine
        FROM _updatableColumns C
            INNER JOIN _types T
            ON C.user_type_id = T.user_type_id
        WHERE C.is_nullable <> 0 AND
              C.user_type_id <> 241   -- Exclude XML columns

        -- Compare XML columns
        --
        SELECT @WhereListB + '    Coalesce(Cast(t.[' + [ColumnName] + '] AS varchar(max)), '''') <>' +  INTO _whereListB
                                           '    Coalesce(Cast(s.[' || [ColumnName] || '] AS text), '''') OR' || _newLine
        FROM _updatableColumns C
            INNER JOIN _types T
            ON C.user_type_id = T.user_type_id
        WHERE C.user_type_id = 241

        -- Remove the trailing OR's
        If _whereListA <> '' Then
            _whereListA := Left(_whereListA, char_length(_whereListA) - 5);
        End If;

        If _whereListB <> '' Then
            _whereListB := Left(_whereListB, char_length(_whereListB) - 5);
        End If;

        If _whereListA <> '' And _whereListB <> '' Then
            RAISE INFO '%', _whereListA;
        Else
            If _whereListA <> '' Then
                RAISE INFO '%', _whereListA;
            Else
                RAISE INFO '%', _whereListB;
            End If;
        End If;

        RAISE INFO '%', '    )';

        -- Sql that actually updates the data
        --
        SELECT ''; INTO _list
        SELECT @list + '    [' + [ColumnName] +  '] = s.[' + [ColumnName] +'],' + @newLine INTO _list
        FROM _updatableColumns

        -- Remove the trailing comma
        RAISE INFO '%', 'THEN UPDATE SET ' || _newLine + left(_list, char_length(_list) - 3);

    End If; -- </UpdateMatchingRows>

    ---------------------------------------------------
    -- Sql for inserting new rows
    ---------------------------------------------------
    --
    RAISE INFO '%', 'WHEN NOT MATCHED BY TARGET THEN';

    INSERT INTO _insertableColumns (ColumnName)
    SELECT [name]
    FROM sys.columns
    WHERE object_id = object_id(_tableName) AND
          is_computed = 0 AND     -- Computed column
          user_type_id <> 189     -- Timestamp column

    If Not Exists (Select * from _insertableColumns) Then
        _message := 'Error: table ' || _tableName || ' does not have any columns compatible with a merge statement';
        RAISE INFO '%', _message;
        Return;
    End If;

    _list := '';
    SELECT @list + '[' + ColumnName +'], ' INTO _list
    FROM _insertableColumns

    -- Remove the trailing comma
    SELECT LEFT(@list, LEN(@list) - 1) INTO _list

    RAISE INFO '%', '    INSERT(' || _list || ')';

    _list := '';
    SELECT @list + 's.[' + ColumnName +'], ' INTO _list
    FROM _insertableColumns

    -- Remove the trailing comma
    SELECT LEFT(@list, LEN(@list) - 1) INTO _list

    RAISE INFO '%', '    VALUES(' || _list || ')';

    ---------------------------------------------------
    -- Sql for deleting extra rows
    ---------------------------------------------------
    --
    If _includeDeleteTest = 0 Then
        RAISE INFO '%', 'WHEN NOT MATCHED BY SOURCE THEN DELETE';
    Else
        RAISE INFO '%', 'WHEN NOT MATCHED BY SOURCE And _deleteExtras <> 0 THEN DELETE';
    End If;

    If _includeActionSummary = 0 Then
        RAISE INFO '%', ';';
    Else
    -- <ActionSummaryTable>

        ---------------------------------------------------
        -- Sql to populate the action summary table
        ---------------------------------------------------
        --
        RAISE INFO '%', 'OUTPUT _tableName, $action,';

        ---------------------------------------------------
        -- Loop through the the list of primary keys
        ---------------------------------------------------
        --
        While _continue = 1 Loop

            -- This While loop can probably be converted to a For loop; for example:
            --    For _itemName In
            --        SELECT item_name
            --        FROM TmpSourceTable
            --        ORDER BY entry_id
            --    Loop
            --        ...
            --    End Loop

            -- Moved to bottom of query: TOP 1
            SELECT ColumnName, INTO _currentColumn
                         _isNumberColumn = IsNumberCol,
                         _isDateColumn = IsDateCol
            FROM _primaryKeyColumns
            WHERE ColumnName > _currentColumn
            ORDER BY ColumnName
            LIMIT 1;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount = 0 Then
                _continue := 0;
            Else
            -- <UpdateInsertdDeletedLists>

                If _insertedList <> ''  Then
                    -- Concatenate updated values
                    --
                    _insertedList := _insertedList || ' || '', '' || ';
                    _deletedList := _deletedList  || ' || '', '' || ';
                End If;

                If _isNumberColumn = 0 And _isDateColumn = 0 Then
                    -- Text column
                    --
                    _insertedList := _insertedList || 'Inserted.[' || _currentColumn || ']';
                    _deletedList := _deletedList ||  'Deleted.['  || _currentColumn || ']';
                Else
                    -- Number or Date column
                    --

                    If _isDateColumn = 0 Then
                        _castCharCount := '12' ; -- text
                    Else
                        _castCharCount := '32' ; -- text;
                    End If;

                    _insertedList := _insertedList || 'Cast(Inserted.[' || _currentColumn || '] as varchar(' || _castCharCount || '))';
                    _deletedList := _deletedList ||  'Cast(Deleted.['  || _currentColumn || '] as varchar(' || _castCharCount || '))';
                End If;

            End If; -- </UpdateInsertdDeletedLists>

        End Loop; -- </IteratePrimaryKeys>

        RAISE INFO '%', '       ' || _insertedList || ',';
        RAISE INFO '%', '       ' || _deletedList;
        RAISE INFO '%', '       INTO Tmp_SummaryOfChanges;';

        RAISE INFO '%', '--';
        RAISE INFO '%', 'SELECT _myError = @@error, _myRowCount = @@rowcount';
        RAISE INFO '%', '';

    End If; -- </ActionSummaryTable>

    ---------------------------------------------------
    -- Turn identity insert back on for tables with identities
    ---------------------------------------------------

    If _tableHasIdentity = 1  Then
        RAISE INFO '%', 'SET IDENTITY_INSERT [dbo].[' || _tableName || '] OFF;' || _newLine;
    End If;

Done:
    return 0

END
$$;

COMMENT ON PROCEDURE pc.generate_merge_statement IS 'GenerateMergeStatement';
