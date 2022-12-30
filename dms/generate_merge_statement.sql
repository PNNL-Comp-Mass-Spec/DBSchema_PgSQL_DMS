--
-- Name: generate_merge_statement(text, text, text, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.generate_merge_statement(_tablename text, _sourceschema text DEFAULT 'public'::text, _targetschema text DEFAULT 'target_schema'::text, _includedeletetest boolean DEFAULT true) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Creates a Merge statement for the specified table (which must exist in schema _sourceSchema)
**
**          Does not actually perform the merge, just generates the code required to do so
**          Intended for use when you need to add a merge statement to a stored procedure
**
**          Modeled after code from http://weblogs.sqlteam.com/billg/archive/2011/02/15/generate-merge-statements-FROM-a-table.aspx
**
**  Arguments:
**    _tableName            Source table name
**    _sourceSchema         Source table schema
**    _targetSchema         Target schema name
**    _includeDeleteTest    When false, use "WHEN NOT MATCHED BY SOURCE And t.PrimaryKeyColumn = _targetItemID THEN DELETE"
**                          When true,  use "WHEN NOT MATCHED BY SOURCE And t.PrimaryKeyColumn = _targetItemID And _deleteExtras THEN DELETE"
**
**  Auth:   mem
**  Date:   10/26/2015 mem - Initial version
**          10/27/2015 mem - Add _includeCreateTableSql
**          11/30/2018 mem - Use DELETE FROM instead of Truncate
**          11/06/2019 mem - Add an additional test to the WHEN NOT MATCHED BY SOURCE clause
**          01/06/2022 mem - Fix bug showing target table name in the action table
**          11/15/2022 mem - Ported to PostgreSQL
**          12/30/2022 mem - Removed _includeActionSummary and _includeCreateTableSQL since PostgreSQL does not support creating a change summary table
**
*****************************************************/
DECLARE
    _message text;
    _validatedSchema text;
    _validatedTable text;
    _columnName text;
    _dataTypeName text;
    _newLine text;
    _list text := '';
    _whereListA text := '';
    _whereListB text := '';
    _whereListC text := '';
    _firstPrimaryKeyColumn text;
    _columnInfo record;
    _insertedList text := '';
    _deletedList text := '';
BEGIN
    _tableName := Coalesce(_tableName, '');
    _sourceSchema := Coalesce(_sourceSchema, '');
    _targetSchema := Coalesce(_targetSchema, 'target_schema');

    _includeDeleteTest := Coalesce(_includeDeleteTest, true);
    _message := '';

    If _tableName = '' Then
        _message := '_tableName cannot be empty';
        RETURN _message;
    End If;

    If _sourceSchema = '' Then
        _message := '_sourceSchema cannot be empty';
        RETURN _message;
    End If;

    If _targetSchema = '' Then
        _targetSchema := 'target_schema';
    End If;

    _newLine := chr(10);

    ---------------------------------------------------
    -- Validate the table name and schema name
    ---------------------------------------------------

    SELECT schemaname, tablename
    INTO _validatedSchema, _validatedTable
    FROM pg_catalog.pg_tables
    WHERE schemaname::citext = _sourceSchema AND
          tablename::citext = _tableName;

    If Not FOUND Then
        _message := format('Cannot generate a merge statement for %I.%I: Table not found', _sourceSchema, _tableName);
        RETURN _message;
    End If;

    _sourceSchema := _validatedSchema;
    _tableName := _validatedTable;

    CREATE TEMP TABLE Tmp_PrimaryKeyColumns (
        ColumnName text NOT NULL,
        data_type_id int NOT NULL,
        IsNumberCol boolean NOT NULL,           -- True if a number or boolean
        IsDateCol boolean NOT NULL,
        UndefinedComparison boolean NOT NULL);  -- True if this procedure does not have logic for comparing two values of this type

    CREATE TEMP TABLE Tmp_UpdatableColumns  (
        ColumnName text NOT NULL,
        data_type_id int NOT NULL,
        is_nullable boolean NOT NULL,
        UndefinedComparison boolean NOT NULL);

    CREATE TEMP TABLE Tmp_InsertableColumns (
        ColumnName text NOT NULL);

    CREATE TEMP TABLE Tmp_Types (
        data_type_id int NOT NULL,
        data_type_name text NOT NULL,
        IsNumber boolean NOT NULL default false,                -- True if a number or boolean
        IsTimestamp boolean NOT NULL default false,
        UndefinedComparison boolean NOT NULL default false);    -- True if this procedure does not have logic for comparing two values of this type

    CREATE TEMP TABLE Tmp_SQL (
        entry_id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        value text
    );

    ---------------------------------------------------
    -- Query to see data type IDs and names (excludes arrays, geometry, ranges, and other system types):
    --
    -- SELECT "oid", typname, typlen, typcategory, typispreferred, typrelid, typnotnull
    -- FROM  pg_catalog.pg_type
    -- WHERE typnamespace = 11 AND
    --       NOT typcategory In ('A', 'C', 'G', 'P', 'R', 'X')
    -- ORDER BY typcategory, oid;
    ---------------------------------------------------

    ---------------------------------------------------
    -- Query to find data types in use in the database:
    --
    -- SELECT a.atttypid as data_type_id,
    --        pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
    --        COUNT(*) AS Column_Count
    -- FROM pg_catalog.pg_attribute a
    --      INNER JOIN pg_catalog.pg_class ON pg_class.oid = a.attrelid
    --      INNER JOIN pg_catalog.pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    -- WHERE a.attnum > 0 AND
    --       NOT a.attisdropped AND
    --       NOT pg_namespace.nspname IN ('pg_catalog', 'pg_toast', 'pnnldata', 'squeeze', 'information_schema')
    -- GROUP BY a.atttypid,
    --          pg_catalog.format_type(a.atttypid, a.atttypmod)
    -- ORDER BY a.atttypid;
    ---------------------------------------------------

    ---------------------------------------------------
    -- Populate a table with list of known data types
    ---------------------------------------------------

    INSERT INTO Tmp_Types (data_type_id, data_type_name, IsNumber, IsTimestamp)
    VALUES (16, 'boolean',           true, false),
           (20, 'bigint',            true, false),      -- int8
           (21, 'smallint',          true, false),      -- int2
           (23, 'integer',           true, false),      -- int4
           (700, 'real',             true, false),      -- float4
           (701, 'double precision', true, false),      -- float8
           (790, 'money',            true, false),
           (1700, 'numeric(18,1)',   true, false),
           (13395, 'information_schema.cardinal_number', true, false),

           -- Text (string) columns
           (18, 'char',                     false, false),
           (19, 'name',                     false, false),
           (25, 'text',                     false, false),
           (142, 'xml',                     false, false),              -- XML (can compare two values by casting to text)
           (1042, 'character(255)',         false, false),              -- bpchar
           (1043, 'character varying(255)', false, false),              -- varchar
           (2950, 'uuid',                   false, false),              -- uniqueidentifier; compatible with Coalesce(ColumnName, '')
           (16385, 'citext',                false, false),
           (13398, 'information_schema.character_data', false, false),
           (13400, 'information_schema.sql_identifier', false, false),
           (13408, 'information_schema.yes_or_no',      false, false),

           -- Date / time columns
           (1082, 'date',                           false, true),
           (1083, 'time',                           false, true),
           (1114, 'timestamp without time zone',    false, true),
           (1184, 'timestamp with time zone',       false, true),
           (1266, 'time with time zone',            false, true),
           (13406, 'information_schema.time_stamp', false, true);

    -- Append additional data types for which we do not have logic below for comparing column values
    INSERT INTO Tmp_Types (data_type_id, data_type_name, UndefinedComparison)
    VALUES (17, 'bytea',      true),
           (24, 'regproc',    true),
           (26, 'oid',        true),
           (27, 'tid',        true),
           (28, 'xid',        true),
           (29, 'cid',        true),
           (114, 'json',      true),
           (650, 'cidr',      true),      -- IP address or netmask (e.g., 192.168.0.1/24)
           (869, 'inet',      true),      -- IP address (IPv4 or IPv6)
           (774, 'macaddr8',  true),      -- MAC addresse
           (829, 'macaddr',   true),      -- MAC addresse
           (1186, 'interval', true),
           (1560, 'bit',      true),
           (1562, 'varbit',   true),
           (2205, 'regclass', true),
           (2206, 'regtype',  true),
           (2275, 'cstring',  true);

    ---------------------------------------------------
    -- Show a message if the table has an identity column
    ---------------------------------------------------

    If Exists (SELECT * FROM information_schema.columns
               WHERE table_schema = _sourceSchema AND
                     table_name = _tableName AND
                     is_identity = 'YES') Then

        INSERT INTO Tmp_SQL (value) VALUES ('');
        INSERT INTO Tmp_SQL (value) VALUES ('-- Use OVERRIDING SYSTEM VALUE to insert an explicit value for the identity column, for example:');
        INSERT INTO Tmp_SQL (value) VALUES ('');
        INSERT INTO Tmp_SQL (value) VALUES ('INSERT INTO mc.t_log_entries (entry_id, posted_by, posting_time, type, message)');
        INSERT INTO Tmp_SQL (value) VALUES ('OVERRIDING SYSTEM VALUE');
        INSERT INTO Tmp_SQL (value) VALUES ('VALUES (12345, ''Test'', CURRENT_TIMESTAMP, ''Test'', ''message'');');
    End If;

    ---------------------------------------------------
    -- Construct the merge statment
    ---------------------------------------------------

    INSERT INTO Tmp_SQL (value) VALUES ('');
    INSERT INTO Tmp_SQL (value) VALUES (format('MERGE %I.%I AS t', _targetSchema, _tableName));
    INSERT INTO Tmp_SQL (value) VALUES (format('USING (SELECT * FROM %I.%I) AS s', _sourceSchema, _tableName));

    -- Lookup the names of the primary key columns
    --
    INSERT INTO Tmp_PrimaryKeyColumns (ColumnName, data_type_id, IsNumberCol, IsDateCol, UndefinedComparison)
    SELECT pg_attribute.attname AS column_name,
           pg_attribute.atttypid AS data_type_id,
           -- format_type(pg_attribute.atttypid, pg_attribute.atttypmod) AS data_type_name
           Tmp_Types.IsNumber,
           Tmp_Types.IsTimestamp,
           Tmp_Types.UndefinedComparison
    FROM pg_index, pg_class, pg_attribute, pg_namespace, Tmp_Types
    WHERE indrelid = pg_class.oid AND
          pg_class.relnamespace = pg_namespace.oid AND
          pg_attribute.attrelid = pg_class.oid AND
          pg_attribute.attnum = any(pg_index.indkey) AND
          indisprimary AND
          Tmp_Types.data_type_id = pg_attribute.atttypid AND
          pg_namespace.nspname = _sourceSchema AND
          pg_class.relname = _tableName;                 -- Alternatively, use pg_class.oid = _tableName::regclass

    If Not Exists (Select * From Tmp_PrimaryKeyColumns) Then
        _message := 'Cannot generate a merge statement for ' || _tableName || ' because it does not have a primary key';

        DROP TABLE Tmp_PrimaryKeyColumns;
        DROP TABLE Tmp_UpdatableColumns;
        DROP TABLE Tmp_InsertableColumns;
        DROP TABLE Tmp_Types;
        DROP TABLE Tmp_SQL;

        RETURN _message;
    End If;

    SELECT C.ColumnName,
           T.data_type_name
    INTO _columnName, _dataTypeName
    FROM Tmp_PrimaryKeyColumns C
         INNER JOIN Tmp_Types T
           ON C.data_type_id = T.data_type_id
    WHERE C.UndefinedComparison
    LIMIT 1;

    If FOUND Then
        _message := format('Cannot generate a merge statement for %I.%I because primary key column %s has data type "%s", which this procedure does not support for comparing values',
                            _sourceSchema, _tableName, _columnName, _dataTypeName);

        DROP TABLE Tmp_PrimaryKeyColumns;
        DROP TABLE Tmp_UpdatableColumns;
        DROP TABLE Tmp_InsertableColumns;
        DROP TABLE Tmp_Types;
        DROP TABLE Tmp_SQL;

        RETURN _message;
    End If;

    -- Use the primary key(s) to define the column(s) to join on
    --

    SELECT string_agg(format('t.%I = s.%I', ColumnName, ColumnName), ' AND ')
    INTO _list
    FROM Tmp_PrimaryKeyColumns;

    INSERT INTO Tmp_SQL (value) VALUES (format('ON ( %s )', _list));

    -- Find the updatable columns (those that are not primary keys, identity columns, computed columns, or transaction ID columns)
    --
    INSERT INTO Tmp_UpdatableColumns (ColumnName, data_type_id, is_nullable, UndefinedComparison)
    SELECT a.attname AS column_name,
           a.atttypid AS data_type_id,
           NOT a.attnotnull AS is_nullable,
           T.UndefinedComparison
    FROM pg_catalog.pg_attribute a
         INNER JOIN pg_catalog.pg_class ON pg_class.oid = a.attrelid
         INNER JOIN pg_catalog.pg_namespace ON pg_namespace.oid = pg_class.relnamespace
         INNER JOIN Tmp_Types T ON a.atttypid = T.data_type_id
    WHERE a.attnum > 0 AND
          NOT a.attisdropped  AND
          pg_namespace.nspname = _sourceSchema AND
          pg_class.relname = _tableName AND
          NOT a.attname IN ( SELECT ColumnName FROM Tmp_PrimaryKeyColumns) AND
          a.attidentity = ''  AND               -- Excluded identity columns
          a.attgenerated = '' AND               -- Exclude generated (computed) columns
          NOT a.atttypid IN (26, 27, 28, 29);   -- Exclude object identifiers, including transaction ID columns (xid)

    If Not Exists (Select * from Tmp_UpdatableColumns) Then
        INSERT INTO Tmp_SQL (value) VALUES (
            format('-- Note: all of the columns in table %I.%I are primary keys or identity columns; there are no updatable columns', _sourceSchema, _tableName));
    Else
        SELECT C.ColumnName,
               T.data_type_name
        INTO _columnName, _dataTypeName
        FROM Tmp_UpdatableColumns C
             INNER JOIN Tmp_Types T
               ON C.data_type_id = T.data_type_id
        WHERE C.UndefinedComparison
        LIMIT 1;

        If FOUND Then
            _message := format('Cannot generate a merge statement for %I.%I because column %s has data type "%s", which this procedure does not support for comparing values',
                                _sourceSchema, _tableName, _columnName, _dataTypeName);

            DROP TABLE Tmp_PrimaryKeyColumns;
            DROP TABLE Tmp_UpdatableColumns;
            DROP TABLE Tmp_InsertableColumns;
            DROP TABLE Tmp_Types;
            DROP TABLE Tmp_SQL;

            RETURN _message;
        End If;

        ---------------------------------------------------
        -- SQL for updating when rows match
        -- Do not update primary keys or identity columns
        ---------------------------------------------------
        --
        INSERT INTO Tmp_SQL (value) VALUES ('WHEN MATCHED AND (');

        ---------------------------------------------------
        -- SQL to determine if matched rows have different values
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
        --                 NULLIF(Source.Field1, Target.Field1)
        --         ) IS NOT NULL
        --
        -- Comparison option #3 (specific to PostgreSQL)
        --  WHERE Source.ColumnA IS DISTINCT FROM Target.ColumnA
        ---------------------------------------------------

        -- Compare the non-nullable columns
        --
        SELECT string_agg(format('    t.%I <> s.%I', C.ColumnName, C.ColumnName), ' OR ' || _newLine)
        INTO _whereListA
        FROM Tmp_UpdatableColumns C
        WHERE Not C.is_nullable AND
              C.data_type_id <> 142;   -- Exclude XML columns

        -- Compare the nullable columns
        --
        SELECT string_agg(format('    t.%I IS DISTINCT FROM s.%I', C.ColumnName, C.ColumnName), ' OR ' || _newLine)
        INTO _whereListB
        FROM Tmp_UpdatableColumns C
        WHERE C.is_nullable AND
              C.data_type_id <> 142;   -- Exclude XML columns

        -- Compare XML columns
        --
        SELECT string_agg(format('    Coalesce(t.%I::text, '''') IS DISTINCT FROM Coalesce(s.%I::text, '''')', C.ColumnName, C.ColumnName), ' OR ' || _newLine)
        INTO _whereListC
        FROM Tmp_UpdatableColumns C
        WHERE C.data_type_id = 142;

        If _whereListA <> '' Then
            INSERT INTO Tmp_SQL (value) VALUES (
                format('%s%s', _whereListA, CASE WHEN _whereListB <> '' OR _whereListC <> '' THEN ' OR' ELSE '' END));
        End If;

        If _whereListB <> '' Then
            INSERT INTO Tmp_SQL (value) VALUES (
                format('%s%s', _whereListB, CASE WHEN _whereListC <> '' THEN ' OR' ELSE '' END));
        End If;

        If _whereListC <> '' Then
            INSERT INTO Tmp_SQL (value) VALUES (_whereListC);
        End If;

        INSERT INTO Tmp_SQL (value) VALUES ('    )');

        -- SQL that actually updates the data
        --

        SELECT string_agg(format('    %I = s.%I', ColumnName, ColumnName), ', ' || _newline)
        INTO _list
        FROM Tmp_UpdatableColumns;

        INSERT INTO Tmp_SQL (value) VALUES ('THEN UPDATE SET');
        INSERT INTO Tmp_SQL (value) VALUES (_list);

    End If;

    ---------------------------------------------------
    -- SQL for inserting new rows
    ---------------------------------------------------
    --
    INSERT INTO Tmp_SQL (value) VALUES ('WHEN NOT MATCHED BY TARGET THEN');

    INSERT INTO Tmp_InsertableColumns (ColumnName)
    SELECT a.attname AS column_name
    FROM pg_catalog.pg_attribute a
         INNER JOIN pg_catalog.pg_class ON pg_class.oid = a.attrelid
         INNER JOIN pg_catalog.pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE a.attnum > 0 AND
          NOT a.attisdropped  AND
          pg_namespace.nspname = _sourceSchema AND
          pg_class.relname = _tableName AND
          a.attgenerated = '' AND               -- Exclude generated (computed) columns
          NOT a.atttypid IN (26, 27, 28, 29);   -- Exclude object identifiers, including transaction ID columns (xid)

    If Not Exists (Select * from Tmp_InsertableColumns) Then
        _message := format('Error: table %I.%I does not have any columns compatible with a merge statement', _sourceSchema, _tableName);

        DROP TABLE Tmp_PrimaryKeyColumns;
        DROP TABLE Tmp_UpdatableColumns;
        DROP TABLE Tmp_InsertableColumns;
        DROP TABLE Tmp_Types;
        DROP TABLE Tmp_SQL;

        RETURN _message;
    End If;

    SELECT string_agg(format('%I', ColumnName), ', ')
    INTO _list
    FROM Tmp_InsertableColumns;

    INSERT INTO Tmp_SQL (value) VALUES (format('    INSERT(%s)', _list));

    SELECT string_agg(format('s.%I', ColumnName), ', ')
    INTO _list
    FROM Tmp_InsertableColumns;

    INSERT INTO Tmp_SQL (value) VALUES (format('    VALUES(%s)', _list));

    ---------------------------------------------------
    -- SQL for deleting extra rows
    ---------------------------------------------------
    --

    SELECT ColumnName
    INTO _firstPrimaryKeyColumn
    FROM Tmp_PrimaryKeyColumns
    LIMIT 1;

    If NOT _includeDeleteTest Then
        INSERT INTO Tmp_SQL (value) VALUES (format('WHEN NOT MATCHED BY SOURCE And t.%I = _targetItemID THEN DELETE', _firstPrimaryKeyColumn));
    Else
        INSERT INTO Tmp_SQL (value) VALUES (format('WHEN NOT MATCHED BY SOURCE And t.%I = _targetItemID And _deleteExtras THEN DELETE', _firstPrimaryKeyColumn));
    End If;

    INSERT INTO Tmp_SQL (value) VALUES (';');

    SELECT string_agg(value, _newline ORDER BY entry_id)
    INTO _message
    FROM Tmp_SQL;

    DROP TABLE Tmp_PrimaryKeyColumns;
    DROP TABLE Tmp_UpdatableColumns;
    DROP TABLE Tmp_InsertableColumns;
    DROP TABLE Tmp_Types;
    DROP TABLE Tmp_SQL;

    RETURN _message;
END
$$;


ALTER FUNCTION public.generate_merge_statement(_tablename text, _sourceschema text, _targetschema text, _includedeletetest boolean) OWNER TO d3l243;

