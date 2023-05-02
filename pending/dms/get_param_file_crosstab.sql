--
CREATE OR REPLACE PROCEDURE public.get_param_file_crosstab
(
    _parameterFileTypeName text = 'Sequest',
    _parameterFileFilter text = '',
    _results refcursor DEFAULT '_results'::refcursor,
    _showValidOnly int = 0,
    _showModSymbol int = 0,
    _showModName int = 1,
    _showModMass int = 1,
    _useModMassAlternativeName int = 1,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _previewSql boolean = false,
    _massModFilterTextColumn text = '',
    _massModFilterText text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns a crosstab table displaying modification details
**      by the Sequest or X!Tandem parameter file
**
**      Results are returned by the RefCursor argument since the number columns in the output table can vary
**
**  Arguments:
**    _parameterFileTypeName     Should be 'Sequest' or 'XTandem'
**    _parameterFileFilter       Optional parameter file name filter
**    _showValidOnly             Set to 1 to only show valid parameter files
**    _showModSymbol             Set to 1 to display the modification symbol
**    _showModName               Set to 1 to display the modification name
**    _showModMass               Set to 1 to display the modification mass
**    _massModFilterTextColumn   If text is defined here, the _massModFilterText filter is only applied to column(s) whose name matches this
**    _massModFilterText         If text is defined here, results are filtered to only show rows that contain this text in one of the mass mod columns
**
**  Date:   12/05/2006 mem - Initial version (Ticket #337)
**          12/11/2006 mem - Renamed from GetSequestParamFileCrosstab to GetParamFileCrosstab (Ticket #342)
**                         - Added parameters _parameterFileTypeName and _showValidOnly
**                         - Updated to call PopulateParamFileInfoTableSequest and PopulateParamFileModInfoTable
**          04/07/2008 mem - Added parameters _previewSql, _massModFilterTextColumn, and _massModFilterText
**          05/19/2009 mem - Now returning column Job_Usage_Count
**          02/12/2010 mem - Expanded _parameterFileFilter to varchar(255)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _paramFileInfoColumnList text;
    _s text;
    _massModFilterSql text;
    _addWildcardChars int;
BEGIN
    _paramFileInfoColumnList := '';

    _s := '';
    _massModFilterSql := '';

    _addWildcardChars := 1;

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    _parameterFileTypeName := Coalesce(_parameterFileTypeName, 'Sequest');
    _parameterFileFilter := Coalesce(_parameterFileFilter, '');
    _showValidOnly := Coalesce(_showValidOnly, 0);
    _showModSymbol := Coalesce(_showModSymbol, 0);
    _showModName := Coalesce(_showModName, 1);
    _showModMass := Coalesce(_showModMass, 1);
    _useModMassAlternativeName := Coalesce(_useModMassAlternativeName, 1);
    _message := '';
    _returnCode := '';
    _previewSql := Coalesce(_previewSql, false);
    _massModFilterTextColumn := Coalesce(_massModFilterTextColumn, '');
    _massModFilterText := Coalesce(_massModFilterText, '');

    -- Make sure _parameterFileTypeName is of a known type
    If _parameterFileTypeName <> 'Sequest' and _parameterFileTypeName <> 'XTandem' Then
        _message := 'Unknown parameter file type: ' || _parameterFileTypeName || '; should be Sequest or XTandem';
        _returnCode := 'U5201';
        RETURN;
    End If;

    If char_length(_parameterFileFilter) > 0 Then
        If _addWildcardChars <> 0 And Position('%' In _parameterFileFilter) = 0 Then
            _parameterFileFilter := '%' || _parameterFileFilter || '%';
        End If;
    Else
        _parameterFileFilter := '%';
    End If;

    -- Assure that one of the following is non-zero
    If _showModSymbol = 0 AND _showModName = 0 AND _showModMass = 0 Then
        _showModName := 1;
    End If;

    -----------------------------------------------------------
    -- Create some temporary tables
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_ParamFileInfo (
        Param_File_ID Int NOT NULL,
        Date_Created timestamp NULL,
        Date_Modified timestamp NULL,
        Job_Usage_Count int NULL
    )
    CREATE UNIQUE INDEX IX_Tmp_ParamFileInfo_Param_File_ID ON Tmp_ParamFileInfo(Param_File_ID);

    CREATE TEMP TABLE Tmp_ParamFileModResults (
        Param_File_ID int
    )
    CREATE UNIQUE INDEX IX_Tmp_ParamFileModResults_Param_File_ID ON Tmp_ParamFileModResults(Param_File_ID);

    -----------------------------------------------------------
    -- Populate a temporary table with the parameter files
    -- matching _parameterFileFilter
    -----------------------------------------------------------

    INSERT INTO Tmp_ParamFileInfo (param_file_id, date_created, date_modified, Job_Usage_Count)
    SELECT PF.param_file_id, PF.date_created, PF.date_modified, PF.Job_Usage_Count
    FROM t_param_file_types PFT INNER JOIN
         t_param_files PF ON PFT.param_file_type_id = PF.param_file_type_id
    WHERE PFT.param_file_type = _parameterFileTypeName AND
          (PF.valid = 1 OR _showValidOnly = 0) AND
          PF.param_file_name LIKE _parameterFileFilter
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------------------------
    -- Possibly append some additional columns to Tmp_ParamFileInfo,
    -- to be included at the beginning of the crosstab report
    -----------------------------------------------------------

    If _parameterFileTypeName = 'Sequest' Then
        Call populate_param_file_info_table_sequest (
                                _paramFileInfoColumnList => _paramFileInfoColumnList,   -- Output
                                _message => _message,                                   -- Output
                                _returnCode => _returnCode);                            -- Output

        If _returnCode <> '' Then
            DROP TABLE Tmp_ParamFileInfo;
            DROP TABLE Tmp_ParamFileModResults;
            RETURN;
        End If;
    End If;

    -----------------------------------------------------------
    -- Populate Tmp_ParamFileModResults
    -----------------------------------------------------------
    Call populate_param_file_mod_info_table (
                        _showModSymbol, _showModName, _showModMass,
                        _useModMassAlternativeName,
                        _massModFilterTextColumn,
                        _massModFilterText,
                        _massModFilterSql => _massModFilterSql, -- Output
                        _message => _message,                   -- Output
                        _returnCode => _returnCode);            -- Output

    If _returnCode <> '' Then
        DROP TABLE Tmp_ParamFileInfo;
        DROP TABLE Tmp_ParamFileModResults;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Return the results
    -----------------------------------------------------------
    _s := '';
    _s := _s || ' SELECT PF.Param_File_Name, PF.Param_File_Description, PF.Job_Usage_Count, ';

    If char_length(Coalesce(_paramFileInfoColumnList, '')) > 0 Then
        _s := _s +      _paramFileInfoColumnList || ', ';
    End If;

    _s := _s ||        ' PFMR.*,';
    _s := _s ||        ' PF.date_created, PF.date_modified, PF.valid';
    _s := _s || ' FROM Tmp_ParamFileInfo PFI INNER JOIN';
    _s := _s ||    ' t_param_files PF ON PFI.param_file_id = PF.param_file_id LEFT OUTER JOIN';
    _s := _s ||    ' Tmp_ParamFileModResults PFMR ON PFI.param_file_id = PFMR.param_file_id';

    If char_length(_massModFilterSql) > 0 Then
        _s := _s || ' WHERE ' || _massModFilterSql;
    End If;

    _s := _s || ' ORDER BY PF.Param_File_Name';

    -- ToDo: Return the query results using the RefCursor

    If _previewSql Then
        RAISE INFO '%', @S;
    Else
        EXECUTE _s;
    End If;

    -----------------------------------------------------------
    -- Exit
    -----------------------------------------------------------

    DROP TABLE Tmp_ParamFileInfo;
    DROP TABLE Tmp_ParamFileModResults;
END
$$;

COMMENT ON PROCEDURE public.get_param_file_crosstab IS 'GetParamFileCrosstab';
