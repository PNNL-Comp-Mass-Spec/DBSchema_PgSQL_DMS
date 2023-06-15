--
CREATE OR REPLACE PROCEDURE public.populate_param_file_info_table_sequest
(
    INOUT _paramFileInfoColumnList text = '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates Tmp_ParamFileInfo to include some additional Sequest-specific columns.
**
**      Returns the list of columns added using parameter _paramFileInfoColumnList
**
**  Date:   12/08/2006 mem - Initial version (Ticket #342)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2023 mem - Ported to PostgreSQL
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

    ALTER TABLE Tmp_ParamFileInfo ADD
        Fragment_Ion_Tolerance real NULL DEFAULT (0) WITH VALUES,
        Enzyme text NULL DEFAULT ('') WITH VALUES,
        Max_Missed_Cleavages int NULL DEFAULT (4) WITH VALUES,
        Parent_Mass_Type text NULL DEFAULT ('Avg') WITH VALUES

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
    )

    INSERT INTO Tmp_ParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('AdvancedParam', 'FragmentIonTolerance', 'float8', 'Fragment_Ion_Tolerance')

    INSERT INTO Tmp_ParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('BasicParam', 'SelectedEnzymeIndex', 'text', 'Enzyme')

    INSERT INTO Tmp_ParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('BasicParam', 'MaximumNumberMissedCleavages', 'int', 'Max_Missed_Cleavages')

    INSERT INTO Tmp_ParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('BasicParam', 'ParentMassType', 'text', 'Parent_Mass_Type')

    -----------------------------------------------------------
    -- Populate the new columns in Tmp_ParamFileInfo
    --
    -- We have to use dynamic Sql here since the columns
    -- were added dynamically to Tmp_ParamFileInfo
    -----------------------------------------------------------

    FOR _paramEntry IN
        SELECT UniqueID,
               TargetDataType,
               TargetColumn
        FROM Tmp_ParamEntryInfo
        ORDER BY UniqueID
    LOOP

        _sql :=        ' UPDATE Tmp_ParamFileInfo'                                           ||
                format(' SET %s = PE.entry_value::%s', _paramEntry.TargetColumn, _paramEntry.TargetDataType) ||
                       ' FROM t_param_entries PE INNER JOIN'
                            ' Tmp_ParamEntryInfo PEI ON PE.entry_type = PEI.entry_type AND'
                            ' PE.entry_specifier = PEI.entry_specifier INNER JOIN'
                            ' Tmp_ParamFileInfo PFI ON PE.param_file_id = PFI.param_file_id' ||
                format(' WHERE PEI.UniqueID = %s', _paramEntry.UniqueID);

        EXECUTE _sql;

    END LOOP;

    -----------------------------------------------------------
    -- Convert Enzyme from a number to a name
    -----------------------------------------------------------

    UPDATE Tmp_ParamFileInfo PFI
    SET Enzyme = Coalesce(Enz.Enzyme_Name, PFI.Enzyme)
    FROM ( SELECT Param_File_ID, public.try_cast(Enzyme, null::int) As EnzymeID
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
    WHERE char_length(Coalesce(Enzyme, '')) = 0 OR Enzyme = '0'

    DROP TABLE Tmp_ParamEntryInfo;
END
$$;

COMMENT ON PROCEDURE public.populate_param_file_info_table_sequest IS 'PopulateParamFileInfoTableSequest';
