--
-- Name: populate_param_file_mod_info_table(integer, integer, integer, integer, text, text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.populate_param_file_mod_info_table(IN _showmodsymbol integer DEFAULT 1, IN _showmodname integer DEFAULT 1, IN _showmodmass integer DEFAULT 0, IN _usemodmassalternativename integer DEFAULT 0, IN _massmodfiltertextcolumn text DEFAULT ''::text, IN _massmodfiltertext text DEFAULT ''::text, IN _previewsql boolean DEFAULT false, INOUT _massmodfiltersql text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Populate temporary table Tmp_ParamFileModResults using the param file IDs in Tmp_ParamFileInfo
**      Both of these tables must be created by the calling procedure
**
**      CREATE TEMP TABLE Tmp_ParamFileInfo (
**          Param_File_ID int NOT NULL,
**          Date_Created timestamp NULL,
**          Date_Modified timestamp NULL,
**          Job_Usage_Count int NULL
**      );
**
**      CREATE TEMP TABLE Tmp_ParamFileModResults (
**          Param_File_ID int
**      );
**
**  Arguments:
**    _showModSymbol                Set to 1 to display the modification symbol
**    _showModName                  Set to 1 to display the modification name
**    _showModMass                  Set to 1 to display the modification mass
**    _useModMassAlternativeName    When 1, use Alternative_Name in t_mass_correction_factors instead of Mass_Correction_Tag
**    _massModFilterTextColumn      If text is defined here, the _massModFilterText filter is only applied to column(s) whose name matches this
**    _massModFilterText            If text is defined here, _massModFilterSql will be populated with SQL to filter the results to only show rows that contain this text in one of the mass mod columns
**    _previewSql                   When true, preview SQL prior to executing it
**    _massModFilterSql             Output: when _massModFilterText is defined, this will have the SQL for filtering on the given text
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   mem
**  Date:   12/08/2006 mem - Initial version (Ticket #342)
**          04/07/2008 mem - Added parameters _massModFilterTextColumn, _massModFilterText, and _massModFilterSql
**          11/30/2018 mem - Renamed the Monoisotopic_Mass and Average_Mass columns
**          07/14/2023 mem - Add parameter _previewSql
**          07/17/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _updateCount int;
    _currentColumn citext;
    _continueAppendDescriptions boolean;
    _modTypeFilter text;
    _sql text;
    _sqlAddon text;
    _mmd text;
    _massModFilterComparison text;
    _addFilter boolean;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    -- Assure that one of the following is non-zero
    If Coalesce(_showModSymbol, 0) = 0 And Coalesce(_showModName, 0) = 0 And Coalesce(_showModMass, 0) = 0 Then
        _showModSymbol := 0;
        _showModName   := 1;
        _showModMass   := 0;
    End If;

    _massModFilterTextColumn := Trim(Coalesce(_massModFilterTextColumn, ''));
    _massModFilterText       := Trim(Coalesce(_massModFilterText, ''));
    _previewSql              := Coalesce(_previewSql, false);

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
    );

    CREATE UNIQUE INDEX IX_Tmp_ParamFileModInfo_Param_File_ID_Mod_Entry_ID ON Tmp_ParamFileModInfo(Param_File_ID, Mod_Entry_ID);

    CREATE TEMP TABLE Tmp_ColumnHeaders (
        UniqueRowID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        ModType text
    );

    CREATE UNIQUE INDEX IX_Tmp_ColumnHeaders_UniqueRowID ON Tmp_ColumnHeaders(UniqueRowID);

    -----------------------------------------------------------
    -- Populate Tmp_ParamFileModInfo
    -----------------------------------------------------------

    _sql := 'INSERT INTO Tmp_ParamFileModInfo (Param_File_ID, Mod_Entry_ID, ModType, Mod_Description) '
            'SELECT PFMM.Param_File_ID, PFMM.Mod_Entry_ID, '
                   'MT.Mod_Type_Synonym || CASE WHEN R.Residue_Symbol IN (''['',''<'') THEN ''_N'' '
                                               'WHEN R.Residue_Symbol IN ('']'',''>'') THEN ''_C'' '
                                               'ELSE ''_'' || R.Residue_Symbol '
                                          'END AS ModType,';

    If _showModSymbol <> 0 Then
        _sql := _sql || ' Coalesce(Local_Symbol, ''-'')';

        If _showModName <> 0 Or _showModMass <> 0 Then
            _sql := _sql || ' || '', '' ||';
        End If;
    End If;

    If _showModName <> 0 Then
        If _useModMassAlternativeName = 0 Then
            _sql := _sql || ' MCF.Mass_Correction_Tag';
        Else
            _sql := _sql || ' CASE WHEN Trim(Coalesce(MCF.Alternative_Name, '''')) <> '''' THEN MCF.Alternative_Name ELSE MCF.Mass_Correction_Tag END';
        End If;

        If _showModMass <> 0 Then
             _sql := _sql || ' || '' ('' ||';
        End If;
    End If;

    If _showModMass <> 0 Then
        _sql := _sql || ' MCF.Monoisotopic_Mass::text';
        If _showModName <> 0 Then
             _sql := _sql || ' || '')''';
        End If;
    End If;

    -- Note that _showModSymbol, _showModName, or _showModMass is guaranteed to be 1, which is why the following text starts with 'AS Mod_Description'

    _sql := _sql ||     ' AS Mod_Description'
                ' FROM Tmp_ParamFileInfo PFI INNER JOIN'
                     ' t_param_file_mass_mods PFMM ON PFI.param_file_id = PFMM.param_file_id INNER JOIN'
                     ' t_mass_correction_factors MCF ON PFMM.mass_correction_id = MCF.mass_correction_id INNER JOIN'
                     ' t_residues R ON PFMM.residue_id = R.residue_id INNER JOIN'
                     ' t_modification_types MT ON PFMM.mod_type_symbol = MT.mod_type_symbol INNER JOIN'
                     ' t_seq_local_symbols_list LSL ON PFMM.local_symbol_id = LSL.local_symbol_id';

    If _previewSql Then
        RAISE INFO '';
        RAISE INFO '%', _sql;
    End If;

    EXECUTE _sql;

    -----------------------------------------------------------
    -- Populate Tmp_ParamFileModResults with the Param File IDs
    -- in Tmp_ParamFileInfo; this may include param files that
    -- do not have any mods
    -----------------------------------------------------------

    INSERT INTO Tmp_ParamFileModResults (Param_File_ID)
    SELECT Param_File_ID
    FROM Tmp_ParamFileInfo
    GROUP BY Param_File_ID;

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

    _sql := 'ALTER TABLE Tmp_ParamFileModResults ';

    SELECT string_agg(format('ADD COLUMN %I text DEFAULT ''''', ModType), ', ' ORDER BY UniqueRowID)
    INTO _sqlAddon
    FROM Tmp_ColumnHeaders;

    _sql := format('%s%s', _sql, _sqlAddon);

    If _previewSql Then
        RAISE INFO '%', _sql;
    End If;

    -- Execute the SQL to alter the table
    EXECUTE _sql;

    -----------------------------------------------------------
    -- Populate Tmp_ParamFileModResults by looping through
    -- the columns in Tmp_ColumnHeaders
    -----------------------------------------------------------

    FOR _currentColumn IN
        SELECT ModType AS CurrentColumn
        FROM Tmp_ColumnHeaders
        ORDER BY UniqueRowID
    LOOP
        If _previewSql Then
            RAISE INFO '';
        End If;

        -----------------------------------------------------------
        -- Loop through the entries for _currentColumn, creating a comma-separated list
        -- of the mods defined for each mod type in each parameter file
        -----------------------------------------------------------
        _continueAppendDescriptions := true;

        WHILE _continueAppendDescriptions
        LOOP

            _modTypeFilter := format('PFMI.ModType = ''%s'' ', _currentColumn);

            _mmd := 'SELECT PFMI.Param_File_ID, MIN(PFMI.Mod_Description) AS Mod_Description '
                    'FROM Tmp_ParamFileModInfo PFMI '                                  ||
                    format('WHERE PFMI.Used = 0 AND %s ', _modTypeFilter)                   ||
                    'GROUP BY Param_File_ID';

            _sql := 'UPDATE Tmp_ParamFileModResults PFMR '
                    'SET %I = PFMR.%I || '
                               'CASE WHEN char_length(PFMR.%I) > 0 '
                               'THEN '', '' '
                               'ELSE '''' '
                               'END || SourceQ.Mod_Description '
                    'FROM ' ||
                  format('(%s) SourceQ ', _mmd)                     ||
                         'WHERE PFMR.Param_File_ID = SourceQ.Param_File_ID';

            If _previewSql Then
                RAISE INFO '%', format(_sql, _currentColumn, _currentColumn, _currentColumn);
            End If;

            EXECUTE format(_sql, _currentColumn, _currentColumn, _currentColumn);

            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            If _previewSql Then
                RAISE INFO '  _updateCount: %', _updateCount;
            End If;

            If _updateCount = 0 Then
                _continueAppendDescriptions := false;
            Else
                _sql := 'UPDATE Tmp_ParamFileModInfo PFMI '
                        'SET Used = 1 ' ||
                        format('FROM (%s) SourceQ ', _mmd)                      ||
                        'WHERE PFMI.Param_File_ID = SourceQ.Param_File_ID AND ' ||
                              'PFMI.Mod_Description = SourceQ.Mod_Description ' ||
                        format('AND %s', _modTypeFilter);

                If _previewSql Then
                    RAISE INFO '%', _sql;
                    RAISE INFO '';
                End If;

                EXECUTE _sql;

            End If;

        END LOOP;

        -----------------------------------------------------------
        -- Possibly populate _massModFilterSql
        -----------------------------------------------------------

        If char_length(_massModFilterText) > 0 Then
            _addFilter := true;
            If char_length(_massModFilterComparison) > 0 Then
                If Not _currentColumn ILIKE _massModFilterComparison Then
                    _addFilter := false;
                End If;
            End If;

            If _addFilter Then
                If char_length(_massModFilterSql) > 0 Then
                    _massModFilterSql := format('%s OR ', _massModFilterSql);
                End If;

                _massModFilterSql := format('%s %I SIMILAR TO ''%s''',
                                           _massModFilterSql,
                                           _currentColumn,
                                           '%' || _massModFilterText || '%');
            End If;
        End If;

    END LOOP;

    DROP TABLE Tmp_ParamFileModInfo;
    DROP TABLE Tmp_ColumnHeaders;
END
$$;


ALTER PROCEDURE public.populate_param_file_mod_info_table(IN _showmodsymbol integer, IN _showmodname integer, IN _showmodmass integer, IN _usemodmassalternativename integer, IN _massmodfiltertextcolumn text, IN _massmodfiltertext text, IN _previewsql boolean, INOUT _massmodfiltersql text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE populate_param_file_mod_info_table(IN _showmodsymbol integer, IN _showmodname integer, IN _showmodmass integer, IN _usemodmassalternativename integer, IN _massmodfiltertextcolumn text, IN _massmodfiltertext text, IN _previewsql boolean, INOUT _massmodfiltersql text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.populate_param_file_mod_info_table(IN _showmodsymbol integer, IN _showmodname integer, IN _showmodmass integer, IN _usemodmassalternativename integer, IN _massmodfiltertextcolumn text, IN _massmodfiltertext text, IN _previewsql boolean, INOUT _massmodfiltersql text, INOUT _message text, INOUT _returncode text) IS 'PopulateParamFileModInfoTable';

