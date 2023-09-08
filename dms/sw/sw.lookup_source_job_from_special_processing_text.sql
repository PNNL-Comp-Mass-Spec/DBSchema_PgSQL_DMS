--
-- Name: lookup_source_job_from_special_processing_text(integer, text, text, text, integer, boolean, text, text, boolean, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.lookup_source_job_from_special_processing_text(IN _job integer, IN _dataset text, IN _specialprocessingtext text, IN _tagname text DEFAULT 'SourceJob'::text, INOUT _sourcejob integer DEFAULT 0, INOUT _autoqueryused boolean DEFAULT false, INOUT _warningmessage text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _previewsql boolean DEFAULT false, INOUT _autoquerysql text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Parses the special processing text in _specialProcessingText
**      to determine the source job defined for a new job
**
**  Arguments:
**    _job                      Job number
**    _dataset                  Dataset Name
**    _specialProcessingText    Special processing text; see below for examples (look for SourceJob:Auto{Tool = "MSGFPlus_MzML_NoRefine")
**    _tagName                  Typically 'SourceJob' or Job2'
**    _sourceJob                Output: source job
**    _autoQueryUsed            Output: true if _specialProcessingText has 'SourceJob:Auto'
**    _warningMessage           Output: warning message
**    _returnCode               Output: return code
**    _autoQuerySql             Output: the auto-query SQL that was used
**
**  Auth:   mem
**  Date:   05/03/2012 mem - Initial version (extracted from LookupSourceJobFromSpecialProcessingParam)
**          05/04/2012 mem - Added parameters _tagName and _autoQueryUsed
**                         - Removed the SourceJobResultsFolder parameter
**          07/12/2012 mem - Added support for $ThisDataset in an Auto-query Where Clause
**          07/13/2012 mem - Added support for $Replace(x,y,z) in an Auto-query Where Clause
**          01/14/2012 mem - Added support for $ThisDatasetTrimAfter(x) in an Auto-query Where Clause
**          03/11/2013 mem - Added output parameter _autoQuerySql
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/30/2022 mem - Update comments to use [Param File]
**          07/25/2023 mem - When parsing the special processing text, replace '[Param File]' with 'Param_File'
**                         - Update comments to use Param_File
**                         - Ported to PostgreSQL
**          08/01/2023 mem - Update _returnCode if an exception is caught
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _currentLocation text := 'Start';
    _sourceJobText text;
    _indexStart int;
    _indexEnd int;
    _whereClause citext := '';
    _orderBy text := '';
    _callingProcName text;
    _part1 citext := '';
    _part2 citext := '';
    _part3 citext := '';
    _textToSearch citext;
    _textToFind citext;
    _replacement citext;
    _message text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _specialProcessingText := Coalesce(_specialProcessingText, '');
    _tagName               := Coalesce(_tagName, 'SourceJob');
    _previewSql            := Coalesce(_previewSql, false);

    ------------------------------------------------
    -- Initialize the outputs
    ------------------------------------------------

    _sourceJob      := 0;
    _autoQueryUsed  := false;
    _warningMessage := '';
    _returnCode     := '';
    _autoQuerySql   := '';

    BEGIN
        If Not _tagName Like '%:' Then
            _tagName := format('%s:', _tagName);
        End If;

        ------------------------------------------------
        -- Parse the Special_Processing text to extract out the source job info
        ------------------------------------------------

        _sourceJobText := sw.extract_tagged_name(_tagName, _specialProcessingText);

        If Coalesce(_sourceJobText, '') <> '' Then
            _sourceJob := public.try_cast(_sourceJobText, null::int);
        End If;

        If _sourceJob Is Null Then
        -- <d>
            -- _sourceJobText is non-numeric

            If _sourceJobText Like 'Auto%' Then
            -- <e>
                -- Parse _specialProcessingText to look for 'SourceJob:Auto' or 'Job2:Auto' (Note that we must process _specialProcessingText since _sourceJobText won't have the full text)
                -- Then find { and }
                -- The text between { and } will be used as a Where clause to query public.V_Source_Analysis_Job to find the best job for this dataset

                -- Example 1:
                --   SourceJob:Auto{Tool = "Decon2LS_V2" AND Settings_File = "Decon2LS_FF_IMS_UseHardCodedFilters_20ppm_NoFlags_2011-02-04.xml"}
                --
                -- Example 2:
                --   SourceJob:Auto{Tool = "XTandem" AND Settings_File = "IonTrapDefSettings_DeconMSN_CIDOnly.xml" AND Param_File = "xtandem_Rnd1PartTryp_Rnd2DynMetOx.xml"}, Job2:Auto{Tool = "MASIC_Finnigan"}
                --
                -- Example 3:
                --   SourceJob:Auto{Tool = "Decon2LS_V2" AND Param_File = "LTQ_FT_Lipidomics_2012-04-16.xml"}, Job2:Auto{Tool = "Decon2LS_V2" AND Param_File = "LTQ_FT_Lipidomics_2012-04-16.xml" AND Dataset LIKE "$Replace($ThisDataset,_Pos,%NEG%)"}
                --
                -- Example 4:
                --   SourceJob:Auto{Tool = "MSGFPlus_MzML_NoRefine" AND (Settings_File = "IonTrapDefSettings_MzML.xml") AND Param_File = "MSGFPlus_Tryp_MetOx_StatCysAlk_20ppmParTol.txt"}, Job2:Auto{Tool = "MASIC_Finnigan"}

                _autoQueryUsed := true;
                _indexStart := Position(format('%sAuto', _tagName) In _specialProcessingText);

                If _indexStart > 0 Then
                -- <f>
                    _whereClause := SUBSTRING(_specialProcessingText, _indexStart + char_length(format('%sAuto', _tagName)), char_length(_specialProcessingText));

                    -- Replace double quotes with single quotes
                    _whereClause := REPLACE(_whereClause, '"', '''');

                    _indexStart := Position('{' In _whereClause);
                    _indexEnd := Position('}' In _whereClause);

                    If _indexStart > 0 And _indexEnd > _indexStart Then
                        _whereClause := SUBSTRING(_whereClause, _indexStart + 1, _indexEnd - _indexStart - 1);
                    Else
                        _whereClause := '';
                    End If;

                    -- Prior to July 2023, the special processing text used [Param File]
                    -- If present, replace with Param_File
                    If Position('[Param File]' IN _whereClause) > 0 Then
                        _whereClause := REPLACE(_whereClause, '[Param File]', 'Param_File');
                    End If;

                    If _whereClause ILike '%$ThisDataset%' Then
                        -- The Where Clause contains a Dataset filter clause utilizing this dataset's name

                        If _whereClause ILike '%$ThisDatasetTrimAfter%' Then
                        -- <g1>
                            -- The Where Clause contains a command of the form: $ThisDatasetTrimAfter(_Pos)
                            -- Find the specified characters in the dataset's name and remove any characters that follow them
                            -- Parse out the $ThisDatasetTrimAfter command and the text inside the parentheses just after the command

                            _indexStart := Position('$ThisDatasetTrimAfter' In _whereClause);
                            _indexEnd   := Position(')' In Substring(_whereClause, _indexStart + 1)) + _indexStart;

                            If _indexStart > 0 And _indexEnd > _indexStart Then
                            -- <h1>

                                _part1 := SUBSTRING(_whereClause, 1,             _indexStart - 1);
                                _part2 := SUBSTRING(_whereClause, _indexStart,   _indexEnd - _indexStart + 1);
                                _part3 := SUBSTRING(_whereClause, _indexEnd + 1, char_length(_whereClause));

                                -- The DatasetTrimmed directive is now in _part2, for example: $ThisDatasetTrimAfter(_Pos)
                                -- Parse out the text between the parentheses

                                _indexStart := Position('(' In _part2);
                                _indexEnd   := Position(')' In Substring(_part2, _indexStart + 1)) + _indexStart;

                                If _indexStart > 0 And _indexEnd > _indexStart Then
                                    _textToFind := SUBSTRING(_part2, _indexStart + 1, _indexEnd - _indexStart - 1);

                                    _indexStart := Position(_textToFind In _dataset);

                                    If _indexStart > 0 Then
                                        _dataset := SUBSTRING(_dataset, 1, _indexStart + char_length(_textToFind) - 1);
                                    End If;

                                End If;

                            End If; -- </h1>

                            _whereClause := format('%s%s%s', _part1, _dataset, _part3);
                            _whereClause := format('WHERE (%s)', _whereClause);

                        Else
                            _whereClause := Replace(_whereClause, '$ThisDataset', _dataset);
                            _whereClause := format('WHERE (%s)', _whereClause);
                        End If;
                    Else
                        _whereClause := format('WHERE (Dataset = ''%s'') AND (%s)', _dataset, _whereClause);
                    End If;

                    If _whereClause Like '%$Replace(%' Then
                    -- <g2>
                        -- The Where Clause contains a Replace Text command of the form: $Replace(DatasetName,'_Pos','') or $Replace(DatasetName,_Pos,)
                        -- First split up the where clause to obtain the text before and after the replacement directive

                        _indexStart := Position('$Replace' In _whereClause);
                        _indexEnd   := Position(')' In Substring(_whereClause, _indexStart + 1)) + _indexStart;

                        If _indexStart > 0 And _indexEnd > _indexStart Then
                        -- <h2>

                            _part1 := SUBSTRING(_whereClause, 1, _indexStart - 1);
                            _part2 := SUBSTRING(_whereClause, _indexStart,   _indexEnd - _indexStart + 1);
                            _part3 := SUBSTRING(_whereClause, _indexEnd + 1, char_length(_whereClause));

                            -- The replacement command is now in _part2, for example: $Replace(MyLipidDataset,_Pos,)
                            -- Split this command at the ( and , characters to allow us to perform the replacment

                            _indexStart := Position('(' In _part2);
                            _indexEnd   := Position(',' In Substring(_part2, _indexStart + 1)) + _indexStart;

                            If _indexStart > 0 And _indexEnd > _indexStart Then
                            -- <i2>

                                -- We have determined the text to search
                                _textToSearch := SUBSTRING(_part2, _indexStart + 1, _indexEnd - _indexStart - 1);

                                _indexStart := _indexEnd + 1;
                                _indexEnd   := Position(',' In Substring(_part2, _indexStart + 1)) + _indexStart;

                                If _indexEnd > _indexStart Then
                                -- <j>
                                    -- We have determined the text to match
                                    _textToFind := SUBSTRING(_part2, _indexStart, _indexEnd - _indexStart);

                                    _indexStart := _indexEnd + 1;
                                    _indexEnd   := Position(')' In Substring(_part2, _indexStart + 1)) + _indexStart;

                                    If _indexEnd >= _indexStart Then
                                    -- <k>
                                        -- We have determined the replacement text
                                        _replacement := SUBSTRING(_part2, _indexStart, _indexEnd - _indexStart);

                                        -- Make sure the text doesn't have any single quotes
                                        -- This would be the case if _specialProcessingText originally contained "$Replace($ThisDataset,"_Pos","")%NEG"}'
                                        _textToFind := REPLACE(_textToFind, '''', '');
                                        _replacement := REPLACE(_replacement, '''', '');

                                        -- RAISE INFO '%, [%], [%], [%]', _part2, _textToSearch, _textToFind, _replacement

                                        _part2 := REPLACE(_textToSearch, _textToFind, _replacement);

                                        -- RAISE INFO '%', _part2;

                                        _whereClause := format('%s%s%s', _part1, _part2, _part3);

                                    End If; -- <k>

                                End If; -- <j>
                            End If; -- <i2>
                        End If; -- <h2>

                    End If; -- </g2>

                    -- By default, order by Job Descending
                    -- However, if _whereClause already contains ORDER BY, we don't want to add another one
                    If _whereClause ILike '%ORDER BY%' Then
                        _orderBy := '';
                    Else
                        _orderBy := 'ORDER BY Job Desc';
                    End If;

                    _autoQuerySql := format('SELECT Job FROM public.V_Source_Analysis_Job %s %s LIMIT 1', _whereClause, _orderBy);

                    If _previewSql Then
                        RAISE INFO '%', _autoQuerySql;
                    End If;

                    EXECUTE _autoQuerySql
                    INTO _sourceJob;

                    If _sourceJob = 0 Then
                        _warningMessage := format('Unable to determine SourceJob for job %s using query %s', _job, _autoQuerySql);
                    End If;

                End If; -- </f>

            End If; -- </e>

            If _whereClause = '' And _warningMessage = '' Then
                _warningMessage := format('%s tag is not numeric in the Special_Processing parameter for job %s', _tagName, _job);
                _warningMessage := format('%s; alternatively, can be %sAuto{SqlWhereClause} where SqlWhereClause is the where clause to use to select the best analysis job for the given dataset using public.V_Source_Analysis_Job',
                                            _warningMessage, _tagName);
            End If;
        End If; -- </d>

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _whereClause <> '' Then
            _currentLocation := format('%s; using SQL Where Clause (see separate log entry)', _currentLocation);
        End If;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        If _whereClause <> '' Then
            _warningMessage := format('Query for SourceJob determination for job %s: %s', _job, _autoQuerySql);
            CALL public.post_log_entry ('Debug', _warningMessage, 'Lookup_Source_Job_From_Special_Processing_Text', 'sw');
        End If;

        If _warningMessage = '' Then
            _warningMessage := 'Exception while determining source job and/or results folder';
        End If;

    END;

END
$_$;


ALTER PROCEDURE sw.lookup_source_job_from_special_processing_text(IN _job integer, IN _dataset text, IN _specialprocessingtext text, IN _tagname text, INOUT _sourcejob integer, INOUT _autoqueryused boolean, INOUT _warningmessage text, INOUT _returncode text, IN _previewsql boolean, INOUT _autoquerysql text) OWNER TO d3l243;

--
-- Name: PROCEDURE lookup_source_job_from_special_processing_text(IN _job integer, IN _dataset text, IN _specialprocessingtext text, IN _tagname text, INOUT _sourcejob integer, INOUT _autoqueryused boolean, INOUT _warningmessage text, INOUT _returncode text, IN _previewsql boolean, INOUT _autoquerysql text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.lookup_source_job_from_special_processing_text(IN _job integer, IN _dataset text, IN _specialprocessingtext text, IN _tagname text, INOUT _sourcejob integer, INOUT _autoqueryused boolean, INOUT _warningmessage text, INOUT _returncode text, IN _previewsql boolean, INOUT _autoquerysql text) IS 'LookupSourceJobFromSpecialProcessingText';

