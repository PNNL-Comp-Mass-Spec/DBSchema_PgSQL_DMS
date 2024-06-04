--
-- Name: populate_param_file_info_table_sequest(boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.populate_param_file_info_table_sequest(IN _previewsql boolean DEFAULT false, INOUT _paramfileinfocolumnlist text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update Tmp_ParamFileInfo to include some additional SEQUEST-specific columns
**      Used by get_param_file_crosstab.sql, which will have created the temporary table using
**
**      CREATE TEMP TABLE Tmp_ParamFileInfo (
**          Param_File_ID int NOT NULL,
**          Date_Created timestamp NULL,
**          Date_Modified timestamp NULL,
**          Job_Usage_Count int NULL
**      );
**
**  Arguments:
**    _previewSql               When true, preview SQL prior to executing it
**    _paramFileInfoColumnList  Output: the list of columns added to Tmp_ParamFileInfo
**    _message                  Status message
**    _returnCode               Return code
**
**  Date:   12/08/2006 mem - Initial version (Ticket #342)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          07/17/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _paramEntry record;
    _sql text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Append the new columns to Tmp_ParamFileInfo
    -----------------------------------------------------------

    ALTER TABLE Tmp_ParamFileInfo
    ADD COLUMN Fragment_Ion_Tolerance float8 NULL DEFAULT 0,
    ADD COLUMN Enzyme text NULL DEFAULT '',
    ADD COLUMN Max_Missed_Cleavages int NULL DEFAULT 4,
    ADD COLUMN Parent_Mass_Type text NULL DEFAULT 'Avg';

    _paramFileInfoColumnList := 'Fragment_Ion_Tolerance, Enzyme, Max_Missed_Cleavages, Parent_Mass_Type';

    -----------------------------------------------------------
    -- Create and populate a table to track the columns
    -- to populate in Tmp_ParamFileInfo
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_ParamEntryInfo (
        UniqueID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Entry_Type text,
        Entry_Specifier text,
        TargetDataType text,
        TargetColumn text
    );

    INSERT INTO Tmp_ParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('AdvancedParam', 'FragmentIonTolerance', 'float8', 'Fragment_Ion_Tolerance');

    INSERT INTO Tmp_ParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('BasicParam', 'SelectedEnzymeIndex', 'text', 'Enzyme');

    INSERT INTO Tmp_ParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('BasicParam', 'MaximumNumberMissedCleavages', 'int', 'Max_Missed_Cleavages');

    INSERT INTO Tmp_ParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('BasicParam', 'ParentMassType', 'text', 'Parent_Mass_Type');

    If _previewSql Then
        RAISE INFO '';
    End If;

    -----------------------------------------------------------
    -- Populate the new columns in Tmp_ParamFileInfo
    --
    -- We have to use dynamic SQL here since the columns
    -- were added dynamically to Tmp_ParamFileInfo
    -----------------------------------------------------------

    FOR _paramEntry IN
        SELECT UniqueID,
               TargetDataType,
               TargetColumn
        FROM Tmp_ParamEntryInfo
        ORDER BY UniqueID
    LOOP

        _sql :=        'UPDATE Tmp_ParamFileInfo PFI '                                                       ||
                format('SET %s = PE.entry_value::%s ', _paramEntry.TargetColumn, _paramEntry.TargetDataType) ||
                       'FROM t_param_entries PE '
                            'INNER JOIN Tmp_ParamEntryInfo PEI '
                              'ON PE.entry_type = PEI.entry_type AND '
                                 'PE.entry_specifier = PEI.entry_specifier '
                       'WHERE PE.param_file_id = PFI.param_file_id AND ' ||
                format('PEI.UniqueID = %s', _paramEntry.UniqueID);

        If _previewSql Then
            RAISE INFO '%', _sql;
        End If;

        EXECUTE _sql;

    END LOOP;

    -----------------------------------------------------------
    -- Convert Enzyme from a number to a name
    -----------------------------------------------------------

    UPDATE Tmp_ParamFileInfo PFI
    SET Enzyme = Coalesce(Enz.Enzyme_Name, PFI.Enzyme)
    FROM (SELECT Param_File_ID, public.try_cast(Enzyme, null::int) AS EnzymeID
          FROM Tmp_ParamFileInfo
          WHERE NOT public.try_cast(Enzyme, null::int) IS NULL
         ) UpdateListQ
         LEFT OUTER JOIN t_enzymes Enz
           ON UpdateListQ.EnzymeID = Enz.sequest_enzyme_index
    WHERE PFI.Param_File_ID = UpdateListQ.Param_File_ID;

    -----------------------------------------------------------
    -- Display the enzyme name as 'none' if the enzyme is 0 or null
    -----------------------------------------------------------

    UPDATE Tmp_ParamFileInfo
    SET Enzyme = 'none'
    WHERE char_length(Coalesce(Enzyme, '')) = 0 OR Enzyme = '0';

    DROP TABLE Tmp_ParamEntryInfo;
END
$$;


ALTER PROCEDURE public.populate_param_file_info_table_sequest(IN _previewsql boolean, INOUT _paramfileinfocolumnlist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE populate_param_file_info_table_sequest(IN _previewsql boolean, INOUT _paramfileinfocolumnlist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.populate_param_file_info_table_sequest(IN _previewsql boolean, INOUT _paramfileinfocolumnlist text, INOUT _message text, INOUT _returncode text) IS 'PopulateParamFileInfoTableSequest';

