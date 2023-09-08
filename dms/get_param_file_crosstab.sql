--
-- Name: get_param_file_crosstab(text, text, integer, integer, integer, integer, integer, text, text, boolean, text, text, refcursor); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_param_file_crosstab(IN _analysistoolname text DEFAULT 'MSGFPlus_MzML'::text, IN _parameterfilefilter text DEFAULT ''::text, IN _showvalidonly integer DEFAULT 0, IN _showmodsymbol integer DEFAULT 0, IN _showmodname integer DEFAULT 1, IN _showmodmass integer DEFAULT 1, IN _usemodmassalternativename integer DEFAULT 1, IN _massmodfiltertextcolumn text DEFAULT ''::text, IN _massmodfiltertext text DEFAULT ''::text, IN _previewsql boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, INOUT _results refcursor DEFAULT '_results'::refcursor)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns a crosstab table displaying modification details
**      for the parameter file(s) for the given analysis tool
**
**      Used by web page https://dms2.pnl.gov/get_paramfile_crosstab/param
**
**      Results are returned by the RefCursor argument since the number of columns in the output table can vary
**
**  Arguments:
**    _analysisToolName             Analysis tool name
**    _parameterFileFilter          Optional parameter file name filter
**    _showValidOnly                When 1, only show valid parameter files
**    _showModSymbol                When 1, display the modification symbol
**    _showModName                  When 1, display the modification name
**    _showModMass                  When 1, display the modification mass
**    _useModMassAlternativeName    When 1, use column Alternative_Name for the mod name instead of Mass_Correction_Tag (but only if Alternative_Name is not null or an empty string)
**    _massModFilterTextColumn      If text is defined here, the _massModFilterText filter is only applied to column(s) whose name matches this
**    _massModFilterText            If text is defined here, results are filtered to only show rows that contain this text in one of the mass mod columns
**    _previewSql                   When true, show the SQL that would be used to return the results
**    _message                      Status message
**    _returnCode                   Return code
**    _results                      Output: RefCursor for viewing the results
**
**  Use this to view the data returned by the _results cursor
**  Note that this will result in an error if no matching items are found
**
**      BEGIN;
**          CALL public.get_param_file_crosstab (
**                      _analysisToolName => 'MSGFPlus_MzML',
**                      _parameterFileFilter => 'TMT_16'
**               );
**          FETCH ALL FROM _results;
**      END;
**
**  Date:   12/05/2006 mem - Initial version (Ticket #337)
**          12/11/2006 mem - Renamed from GetSequestParamFileCrosstab to GetParamFileCrosstab (Ticket #342)
**                         - Added parameters _analysisToolName and _showValidOnly
**                         - Updated to call Populate_Param_File_Info_Table_Sequest and Populate_Param_File_Mod_Info_Table
**          04/07/2008 mem - Added parameters _previewSql, _massModFilterTextColumn, and _massModFilterText
**          05/19/2009 mem - Now returning column Job_Usage_Count
**          02/12/2010 mem - Expanded _parameterFileFilter to varchar(255)
**          07/17/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _paramFileInfoColumnList text;
    _sql text;
    _massModFilterSql text;
    _addWildcardChars boolean;
BEGIN
    _message := '';
    _returnCode := '';

    _paramFileInfoColumnList := '';
    _sql                     := '';
    _massModFilterSql        := '';
    _addWildcardChars        := true;

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _analysisToolName          := Trim(Coalesce(_analysisToolName, 'MSGFPlus_MzML'));
    _parameterFileFilter       := Coalesce(_parameterFileFilter, '');
    _showValidOnly             := Coalesce(_showValidOnly, 0);
    _showModSymbol             := Coalesce(_showModSymbol, 0);
    _showModName               := Coalesce(_showModName, 1);
    _showModMass               := Coalesce(_showModMass, 1);
    _useModMassAlternativeName := Coalesce(_useModMassAlternativeName, 1);
    _massModFilterTextColumn   := Coalesce(_massModFilterTextColumn, '');
    _massModFilterText         := Coalesce(_massModFilterText, '');
    _previewSql                := Coalesce(_previewSql, false);

    -- Make sure _analysisToolName corresponds to an analysis tool with entries in T_Param_File_Mass_Mods

    If Not Exists (
        SELECT PFMM.mod_entry_id
        FROM t_param_file_mass_mods PFMM
             INNER JOIN t_param_files PF
               ON PFMM.param_file_id = PF.param_file_id
             INNER JOIN t_analysis_tool AnTool
               ON PF.param_file_type_id = AnTool.param_file_type_id
        WHERE AnTool.analysis_tool = _analysisToolName::citext
    ) Then
        _message := format('Unknown analysis tool: %s (rows not found in T_Param_File_Mass_Mods); should be MSGFPlus_MzML, MaxQuant, DiaNN, XTandem, etc.', _analysisToolName);
        _returnCode := 'U5201';
        RETURN;
    End If;

    If char_length(_parameterFileFilter) > 0 Then
        If _addWildcardChars And Position('%' In _parameterFileFilter) = 0 Then
            _parameterFileFilter := '%' || _parameterFileFilter || '%';
        End If;
    Else
        _parameterFileFilter := '%';
    End If;

    -- Assure that one of the following is non-zero
    If _showModSymbol = 0 And _showModName = 0 And _showModMass = 0 Then
        _showModName := 1;
    End If;

    -----------------------------------------------------------
    -- Create some temporary tables
    -----------------------------------------------------------

    DROP TABLE IF EXISTS Tmp_ParamFileInfo;
    DROP TABLE IF EXISTS Tmp_ParamFileModResults;

    CREATE TEMP TABLE Tmp_ParamFileInfo (
        Param_File_ID int NOT NULL,
        Date_Created timestamp NULL,
        Date_Modified timestamp NULL,
        Job_Usage_Count int NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_ParamFileInfo_Param_File_ID ON Tmp_ParamFileInfo(Param_File_ID);

    CREATE TEMP TABLE Tmp_ParamFileModResults (
        Param_File_ID int
    );

    CREATE UNIQUE INDEX IX_Tmp_ParamFileModResults_Param_File_ID ON Tmp_ParamFileModResults(Param_File_ID);

    -----------------------------------------------------------
    -- Populate a temporary table with the parameter files
    -- that correspond to tool _analysisToolName and
    -- match _parameterFileFilter (which will be '%' if it was '')
    -----------------------------------------------------------

    INSERT INTO Tmp_ParamFileInfo (param_file_id, date_created, date_modified, Job_Usage_Count)
    SELECT PF.param_file_id, PF.date_created, PF.date_modified, PF.job_usage_count
    FROM t_param_files PF
         INNER JOIN t_analysis_tool AnTool
           ON PF.param_file_type_id = AnTool.param_file_type_id
    WHERE AnTool.analysis_tool = _analysisToolName::citext AND
          (PF.Valid = 1 OR _showValidOnly = 0) AND
          PF.Param_File_Name ILIKE _parameterFileFilter;


    -----------------------------------------------------------
    -- Possibly append some additional columns to Tmp_ParamFileInfo,
    -- to be included at the beginning of the crosstab report
    -----------------------------------------------------------

    If _analysisToolName::citext = 'Sequest' Then
        CALL populate_param_file_info_table_sequest (
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

    CALL populate_param_file_mod_info_table (
                        _showModSymbol,
                        _showModName,
                        _showModMass,
                        _useModMassAlternativeName,
                        _massModFilterTextColumn,
                        _massModFilterText,
                        _previewSql => _previewSql,
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

    _sql := 'SELECT PF.Param_File_Name, PF.Param_File_Description, PF.Job_Usage_Count, ' ||
                    CASE WHEN char_length(Coalesce(_paramFileInfoColumnList, '')) > 0
                         THEN format('%s, ', _paramFileInfoColumnList)
                         ELSE ''
                    END ||
                   'PFMR.*, '
                   'PF.date_created, PF.date_modified, PF.valid '
            'FROM Tmp_ParamFileInfo PFI INNER JOIN '
                 't_param_files PF ON PFI.param_file_id = PF.param_file_id LEFT OUTER JOIN '
                 'Tmp_ParamFileModResults PFMR ON PFI.param_file_id = PFMR.param_file_id ' ||
                  CASE WHEN char_length(_massModFilterSql) > 0
                       THEN format('WHERE %s ', _massModFilterSql)
                       ELSE ''
                  END ||
            '    ORDER BY PF.Param_File_Name';

    If _previewSql Then
        RAISE INFO '%', _sql;
    Else
        Open _results For
            EXECUTE _sql;
    End If;

    -- Do not drop the temporary tables since they are referenced by the cursor
END
$$;


ALTER PROCEDURE public.get_param_file_crosstab(IN _analysistoolname text, IN _parameterfilefilter text, IN _showvalidonly integer, IN _showmodsymbol integer, IN _showmodname integer, IN _showmodmass integer, IN _usemodmassalternativename integer, IN _massmodfiltertextcolumn text, IN _massmodfiltertext text, IN _previewsql boolean, INOUT _message text, INOUT _returncode text, INOUT _results refcursor) OWNER TO d3l243;

--
-- Name: PROCEDURE get_param_file_crosstab(IN _analysistoolname text, IN _parameterfilefilter text, IN _showvalidonly integer, IN _showmodsymbol integer, IN _showmodname integer, IN _showmodmass integer, IN _usemodmassalternativename integer, IN _massmodfiltertextcolumn text, IN _massmodfiltertext text, IN _previewsql boolean, INOUT _message text, INOUT _returncode text, INOUT _results refcursor); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.get_param_file_crosstab(IN _analysistoolname text, IN _parameterfilefilter text, IN _showvalidonly integer, IN _showmodsymbol integer, IN _showmodname integer, IN _showmodmass integer, IN _usemodmassalternativename integer, IN _massmodfiltertextcolumn text, IN _massmodfiltertext text, IN _previewsql boolean, INOUT _message text, INOUT _returncode text, INOUT _results refcursor) IS 'GetParamFileCrosstab';

