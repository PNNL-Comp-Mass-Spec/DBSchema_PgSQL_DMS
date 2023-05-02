--
CREATE OR REPLACE PROCEDURE dpkg.reset_identity_field_seed
(
    _infoOnly boolean = false,
    _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Resets the identity field seed in the various
**          data tables to the maximum value (or to the
**          original identity value if the table is empty)
**
**
**  Auth:   mem
**  Date:   12/30/2005
**          02/17/2006 mem - Ported to the DMS
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _tableName text;
    _fieldName text;
    _sql text;
    _paramDef text;
    _identitySeed int;
    _currentIdentity int;
    _maxValue int;
    _rowCount int;
    _continue int;
    _result int;
    _seedToUse int;
    _identityUpdated int;
BEGIN
    _message := '';
    _returnCode:= '';

    /*
    ** Use the following to find all tables in this DB that have identity columns
    **
        SELECT TABLE_NAME, IDENT_CURRENT(TABLE_NAME) AS IDENT_CURRENT
        FROM INFORMATION_SCHEMA.TABLES
        WHERE IDENT_SEED(TABLE_NAME) IS NOT NULL
    **
    */

    --------------------------------------------------------------
    -- Create a temporary table to hold table info and stats
    --------------------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_TablesToUpdate (
        Table_Name text NOT NULL,
        Field_Name text NOT NULL,
        Processed int NOT NULL DEFAULT 0,
        Identity_Updated int NOT NULL DEFAULT 0,
        Identity_Seed int NULL,
        Current_Identity int NULL,
        Max_Value int NULL,
        Row_Count int NULL
    )

    CREATE UNIQUE INDEX IX_Tmp_TablesToUpdate ON Tmp_TablesToUpdate (Table_Name ASC)

    --------------------------------------------------------------
    -- Define the tables to update
    --------------------------------------------------------------
    --
    INSERT INTO Tmp_TablesToUpdate (Table_Name, Field_Name) VALUES ('dpkg.t_data_package',                'data_pkg_id')
    INSERT INTO Tmp_TablesToUpdate (Table_Name, Field_Name) VALUES ('dpkg.t_data_package_storage',        'data_pkg_id')

    --------------------------------------------------------------
    -- The following is used in the call to sp_EXECUTE sql
    --------------------------------------------------------------
    --
    _paramDef := '_identitySeed int output, _currentIdentity int output, _maxValue int output, _rowCount int output';

    --------------------------------------------------------------
    -- Loop through the entries in Tmp_TablesToUpdate
    --------------------------------------------------------------
    --
    _continue := 1;
    While _continue = 1 And _myError = 0 Loop
        --------------------------------------------------------------
        -- Lookup the next table to process
        --------------------------------------------------------------
        --
        -- This While loop can probably be converted to a For loop; for example:
        --    FOR _itemName IN
        --        SELECT item_name
        --        FROM TmpSourceTable
        --        ORDER BY entry_id
        --    LOOP
        --        ...
        --    END LOOP

        -- Moved to bottom of query: TOP 1
        SELECT Field_Name INTO _fieldName
        FROM Tmp_TablesToUpdate
        WHERE Processed = 0
        ORDER BY Table_Name
        LIMIT 1;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount < 1 Then
            _continue := 0;
        Else
            --------------------------------------------------------------
            -- Lookup the current identity stats, maximum value, and number of rows
            --------------------------------------------------------------
            --
            _identitySeed := 0;
            _currentIdentity := 0;
            _maxValue := 0;
            _rowCount := 0;

            _sql := '';
            _sql := _sql || ' SELECT _identitySeed = IDENT_SEED(''' || _tableName || '''),';
            _sql := _sql ||        ' _currentIdentity = Coalesce(IDENT_CURRENT(''' || _tableName || '''),0),';
            _sql := _sql ||        ' _maxValue = Coalesce(Max(' || _fieldName || '),0),';
            _sql := _sql ||        ' _rowCount = COUNT(*)';
            _sql := _sql || ' FROM ' || _tableName;

            Call _result => sp_EXECUTE sql _sql, _paramDef, _identitySeed => _identitySeed output,
                                                          _currentIdentity = _currentIdentity output,
                                                          _maxValue = _maxValue output,
                                                          _rowCount = _rowCount output
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            --------------------------------------------------------------
            -- Possibly update the identity
            --------------------------------------------------------------
            --
            _identityUpdated := 0;
            --
            If _result = 0 AND _myError = 0 AND _infoOnly = false Then
                If _rowCount = 0 OR _currentIdentity > _maxValue AND _currentIdentity > _identitySeed Then
                    If _rowCount = 0 Then
                        _seedToUse := _identitySeed-1;
                    Else
                        If _maxValue < _identitySeed Then
                            _seedToUse := _identitySeed-1;
                        Else
                            _seedToUse := _maxValue;
                        End If;
                    End If;
                    DBCC CHECKIDENT (_tableName, RESEED, _seedToUse)
                    _identityUpdated := 1;
                End If;
            End If;

            UPDATE Tmp_TablesToUpdate
            SET Identity_Seed = _identitySeed,
                Current_Identity = _currentIdentity,
                Max_Value = _maxValue,
                Row_Count = _rowCount,
                Processed = 1,
                Identity_Updated = _identityUpdated
            WHERE Table_Name = _tableName
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        End If;
    End Loop;

    SELECT    Table_Name, Field_Name,
            Identity_Updated, Identity_Seed,
            Current_Identity, Max_Value,
            CASE WHEN Row_Count > 0
            THEN Current_Identity - Max_Value
            ELSE 0
            END AS Difference
    FROM Tmp_TablesToUpdate
    ORDER BY Table_Name

    Return _myError

    DROP TABLE Tmp_TablesToUpdate
END
$$;

COMMENT ON PROCEDURE dpkg.reset_identity_field_seed IS 'ResetIdentityFieldSeed';
