--
CREATE OR REPLACE PROCEDURE public.populate_param_file_mod_info_table
(
    _showModSymbol int = 1,
    _showModName int = 1,
    _showModMass int = 0,
    _useModMassAlternativeName int = 0,
    _massModFilterTextColumn text = '',
    _massModFilterText text = '',
    _massModFilterSql text = ''output,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Populates temporary table Tmp_ParamFileModResults using the param file IDs in Tmp_ParamFileInfo
**
**      Both of these tables needs to be created by the calling procedure
**
**  Arguments:
**    _showModSymbol             Set to 1 to display the modification symbol
**    _showModName               Set to 1 to display the modification name
**    _showModMass               Set to 1 to display the modification mass
**    _massModFilterTextColumn   If text is defined here, the _massModFilterText filter is only applied to column(s) whose name matches this
**    _massModFilterText         If text is defined here, _massModFilterSql will be populated with SQL to filter the results to only show rows that contain this text in one of the mass mod columns
**
**  Auth:   mem
**  Date:   12/08/2006 mem - Initial version (Ticket #342)
**          04/07/2008 mem - Added parameters _massModFilterTextColumn, _massModFilterText, and _massModFilterSql
**          11/30/2018 mem - Renamed the Monoisotopic_Mass and Average_Mass columns
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _currentColumn citext;
    _columnHeaderRowID int;
    _continueAppendDescriptions boolean;
    _modTypeFilter text;
    _s text;
    _mmd text;
    _massModFilterComparison text;
    _addFilter boolean;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    -- Assure that one of the following is non-zero
    If Coalesce(_showModSymbol, 0) = 0 AND Coalesce(_showModName, 0) = 0 AND Coalesce(_showModMass, 0) = 0 Then
        _showModSymbol := 0;
        _showModName := 1;
        _showModMass := 0;
    End If;

    _massModFilterTextColumn := Coalesce(_massModFilterTextColumn, '');
    _massModFilterText := Coalesce(_massModFilterText, '');

    _massModFilterSql := '';

    If char_length(_massModFilterTextColumn) > 0 Then
        _massModFilterComparison := '%' || _massModFilterTextColumn || '%';
    Else
        _massModFilterComparison := '';
    End If;

    -----------------------------------------------------------
    -- Create some temporary tables
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_ParamFileModInfo (
        Param_File_ID int NOT NULL,
        Mod_Entry_ID int NOT NULL,
        ModType text NULL,
        Mod_Description text NULL,
        Used int DEFAULT 0
    )
    CREATE UNIQUE INDEX IX_Tmp_ParamFileModInfo_Param_File_ID_Mod_Entry_ID ON Tmp_ParamFileModInfo(Param_File_ID, Mod_Entry_ID);

    CREATE TEMP TABLE Tmp_ColumnHeaders (
        UniqueRowID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        ModType text
    )
    CREATE UNIQUE INDEX IX_Tmp_ColumnHeaders_UniqueRowID ON Tmp_ColumnHeaders(UniqueRowID);

    -----------------------------------------------------------
    -- Populate Tmp_ParamFileModInfo
    -----------------------------------------------------------

    _s := '';
    _s := _s || ' INSERT INTO Tmp_ParamFileModInfo (Param_File_ID, Mod_Entry_ID, ModType, Mod_Description)';
    _s := _s || ' SELECT PFMM.Param_File_ID, PFMM.Mod_Entry_ID, ';
    _s := _s ||         ' MT.Mod_Type_Synonym + CASE WHEN R.Residue_Symbol IN (''['',''<'') THEN ''_N''';
    _s := _s ||                               ' WHEN R.Residue_Symbol IN ('']'',''>'') THEN ''_C''';
    _s := _s ||                               ' ELSE ''_'' || R.Residue_Symbol ';
    _s := _s ||                               ' END AS ModType,';

    If _showModSymbol <> 0 Then
        _s := _s || ' Coalesce(Local_Symbol, ''-'') ';

        If _showModName <> 0 OR _showModMass <> 0 Then
            _s := _s || ' || '', '' || ';
        End If;
    End If;

    If _showModName <> 0 Then
        If _useModMassAlternativeName = 0 Then
            _s := _s || ' RTRIM(MCF.Mass_Correction_Tag)';
        Else
            _s := _s || ' Coalesce(Alternative_Name, RTRIM(MCF.Mass_Correction_Tag))';
        End If;

        If _showModMass <> 0 Then
             _s := _s || ' || '' ('' || ';
        End If;
    End If;

    If _showModMass <> 0 Then
        _s := _s || ' MCF.Monoisotopic_Mass::text';
        If _showModName <> 0 Then
             _s := _s || ' || '')''';
        End If;
    End If;

    _s := _s ||     ' AS Mod_Description';

    _s := _s || ' FROM Tmp_ParamFileInfo PFI INNER JOIN ';
    _s := _s ||      ' t_param_file_mass_mods PFMM ON PFI.param_file_id = PFMM.param_file_id INNER JOIN';
    _s := _s ||      ' t_mass_correction_factors MCF ON PFMM.mass_correction_id = MCF.mass_correction_id INNER JOIN';
    _s := _s ||      ' t_residues R ON PFMM.residue_id = R.residue_id INNER JOIN';
    _s := _s ||      ' t_modification_types MT ON PFMM.mod_type_symbol = MT.mod_type_symbol INNER JOIN';
    _s := _s ||      ' t_seq_local_symbols_list LSL ON PFMM.local_symbol_id = LSL.local_symbol_id';

    EXECUTE _s;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------------------------
    -- Populate Tmp_ParamFileModResults with the Param File IDs
    -- in Tmp_ParamFileInfo; this may include param files that
    -- do not have any mods
    -----------------------------------------------------------

    INSERT INTO Tmp_ParamFileModResults (Param_File_ID)
    SELECT Param_File_ID
    FROM Tmp_ParamFileInfo
    GROUP BY Param_File_ID
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------------------------
    -- Generate a list of the unique mod types in Tmp_ParamFileModInfo
    -- Use these to define the column headers for the crosstab
    -----------------------------------------------------------
    INSERT INTO Tmp_ColumnHeaders (ModType)
    SELECT ModType
    FROM Tmp_ParamFileModInfo
    GROUP BY ModType
    ORDER BY ModType;

    If Not FOUND Then
        DROP TABLE Tmp_ParamFileModInfo;
        DROP TABLE Tmp_ColumnHeaders;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Use the columns in Tmp_ColumnHeaders to dynamically add
    -- columns to Tmp_ParamFileModResults
    --
    -- By using DEFAULT('') WITH VALUES, all of the rows will
    --  have blank, non-Null values for these new columns
    -----------------------------------------------------------

    _s := '';
    _s := _s || ' ALTER TABLE Tmp_ParamFileModResults ADD ';

    SELECT string_agg('[' || ModType || '] text DEFAULT ('''') WITH VALUES ', ', ')
    INTO _s
    FROM Tmp_ColumnHeaders
    ORDER BY UniqueRowID

    -- Execute the Sql to alter the table
    EXECUTE _s;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------------------------
    -- Populate Tmp_ParamFileModResults by looping through
    -- the Columns in Tmp_ColumnHeaders
    -----------------------------------------------------------

    FOR _currentColumn _columnHeaderRowID IN
        SELECT ModType AS CurrentColumn
               UniqueRowID AS ColumnHeaderRowID
        FROM Tmp_ColumnHeaders
        ORDER BY UniqueRowID
    LOOP

        -----------------------------------------------------------
        -- Loop through the entries for _currentColumn, creating a comma separated list
        -- of the mods defined for each mod type in each parameter file
        -----------------------------------------------------------
        _continueAppendDescriptions := true;

        WHILE _continueAppendDescriptions
        LOOP

            _modTypeFilter := format('(ModType = ''%s'')', _currentColumn);

            _mmd := '';
            _mmd := _mmd || ' SELECT Param_File_ID, MIN(Mod_Description) AS Mod_Description';
            _mmd := _mmd || ' FROM Tmp_ParamFileModInfo';
            _mmd := _mmd || ' WHERE (Used = 0) AND ' || _modTypeFilter;
            _mmd := _mmd || ' GROUP BY Param_File_ID';

            _s := '';
            _s := _s || ' UPDATE Tmp_ParamFileModResults';
            _s := _s || ' SET %I = %I || ';
            _s := _s ||            ' CASE WHEN char_length(%I) > 0';
            _s := _s ||            ' THEN '', '' ';
            _s := _s ||            ' ELSE '''' ';
            _s := _s ||            ' END || SourceQ.Mod_Description';
            _s := _s || ' FROM Tmp_ParamFileModResults PFMR INNER JOIN';
            _s := _s ||      ' (' || _mmd || ') SourceQ ';
            _s := _s ||      ' ON PFMR.Param_File_ID = SourceQ.Param_File_ID';
            --
            EXECUTE format(_s, _currentColumn, _currentColumn, _currentColumn);
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount = 0 Then
                _continueAppendDescriptions := false;
            Else
                _s := '';
                _s := _s || ' UPDATE Tmp_ParamFileModInfo';
                _s := _s || ' SET Used = 1';
                _s := _s || ' FROM Tmp_ParamFileModInfo PFMI INNER JOIN';
                _s := _s ||      ' (' || _mmd || ') SourceQ';
                _s := _s ||      ' ON PFMI.Param_File_ID = SourceQ.Param_File_ID AND';
                _s := _s ||         ' PFMI.Mod_Description = SourceQ.Mod_Description';
                _s := _s || ' WHERE ' || _modTypeFilter;
                --
                EXECUTE _s;

            End If;

        END LOOP;

        -----------------------------------------------------------
        -- Possibly populate _massModFilterSql
        -----------------------------------------------------------
        If char_length(_massModFilterText) > 0 Then
            _addFilter := true;
            If char_length(_massModFilterComparison) > 0 Then
                If Not _currentColumn LIKE _massModFilterComparison Then
                    _addFilter := false;
                End If;
            End If;

            If _addFilter Then
                If char_length(_massModFilterSql) > 0 Then
                    _massModFilterSql := _massModFilterSql || ' OR ';
                End If;

                _massModFilterSql := _massModFilterSql ||
                                     format(' %I ', _currentColumn) ||
                                     'LIKE ''%' || _massModFilterText || '%''';
            End If;
        End If;

    END LOOP;

    DROP TABLE Tmp_ParamFileModInfo;
    DROP TABLE Tmp_ColumnHeaders;
END
$$;

COMMENT ON PROCEDURE public.populate_param_file_mod_info_table IS 'PopulateParamFileModInfoTable';
