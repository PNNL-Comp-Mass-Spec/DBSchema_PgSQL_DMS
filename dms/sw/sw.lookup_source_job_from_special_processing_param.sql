--
-- Name: lookup_source_job_from_special_processing_param(text, text, boolean, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.lookup_source_job_from_special_processing_param(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _previewsql boolean DEFAULT false, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Looks up the source job defined for a new job
**
**      The calling procedure must create temp table Tmp_Source_Job_Folders
**
**      CREATE TEMP TABLE Tmp_Source_Job_Folders (
**          Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
**          Job int NOT NULL,
**          Step int NOT NULL,
**          SourceJob int NULL,
**          SourceJobResultsFolder text NULL,
**          SourceJob2 int NULL,
**          SourceJob2Dataset text NULL,
**          SourceJob2FolderPath text NULL,
**          SourceJob2FolderPathArchive text NULL,
**          WarningMessage text NULL
**      );
**
**  Arguments:
**    _message          Output: status message
**    _returnCode       Output: return code
**    _previewSql       When true, set _previewSql to true when calling sw.lookup_source_job_from_special_processing_text()
**    _showDebug        When true, show debug messages
**
**  Auth:   mem
**  Date:   03/21/2011 mem - Initial Version
**          04/04/2011 mem - Updated to use the Special_Processing param instead of the job comment
**          04/20/2011 mem - Updated to support cases where _specialProcessingText contains ORDER BY
**          05/03/2012 mem - Now calling Lookup_Source_Job_From_Special_Processing_Text to parse _specialProcessingText
**          05/04/2012 mem - Now passing _tagName and _autoQueryUsed to Lookup_Source_Job_From_Special_Processing_Text
**          07/12/2012 mem - Now looking up details for Job2 (if defined in the Special_Processing text)
**          07/13/2012 mem - Now storing SourceJob2Dataset in Tmp_Source_Job_Folders
**          03/11/2013 mem - Now overriding _sourceJobResultsFolder if there is a problem determining the details for Job2
**          02/23/2016 mem - Add set XACT_ABORT on
**          07/25/2023 mem - Ported to PostgreSQL
**          08/01/2023 mem - Update _returnCode if an exception is caught
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/11/2023 mem - Add parameter _showDebug
**                         - Only compare _sourceJob and _sourceJob2 if _sourceJobValid is true
**
*****************************************************/
DECLARE
    _currentLocation text := 'Start';
    _entryID int;
    _job int;
    _dataset text;
    _tagName text;
    _specialProcessingText citext;
    _sourceJob int;
    _autoQueryUsed boolean;
    _sourceJobResultsFolder text;
    _sourceJobResultsFolderOverride text;
    _sourceJobValid boolean;
    _sourceJob2 int;
    _sourceJob2Dataset text;
    _sourceJob2FolderPath text;
    _sourceJob2FolderPathArchive text;
    _autoQuerySql text;
    _warningMessage text;
    _logMessage text;
    _callingProcName text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := Trim(Coalesce(_message, ''));
    _returnCode := '';

    _previewSql := Coalesce(_previewSql, false);
    _showDebug  := Coalesce(_showDebug, false);

    ---------------------------------------------------
    -- Step through each entry in Tmp_Source_Job_Folders
    ---------------------------------------------------

    FOR _entryID, _job IN
        SELECT Entry_ID, Job
        FROM Tmp_Source_Job_Folders
        ORDER BY Entry_ID
    LOOP

        BEGIN
            _currentLocation := format('Determining SourceJob for job %s', _job);

            If _showDebug Then
                RAISE INFO '';
                RAISE INFO '%', _currentLocation;
            End If;

            _dataset := '';
            _specialProcessingText := '';
            _sourceJob := 0;
            _autoQueryUsed := false;
            _sourceJobResultsFolder := 'UnknownFolder_Invalid_SourceJob';
            _sourceJobResultsFolderOverride := '';
            _warningMessage := '';
            _sourceJobValid := false;
            _autoQuerySql := '';

            -------------------------------------------------
            -- Lookup the Dataset for this job
            -------------------------------------------------

            SELECT dataset
            INTO _dataset
            FROM sw.t_jobs
            WHERE job = _job;

            If Not FOUND Then
                -- Job not found
                --
                _warningMessage := format('Job %s not found in sw.t_jobs', _job);

                If _showDebug Then
                    RAISE WARNING '%', _warningMessage;
                End If;

            Else

                -- Lookup the Special_Processing parameter for this job
                --
                SELECT Value
                INTO _specialProcessingText
                FROM sw.get_job_param_table_local(_job)
                WHERE Name = 'Special_Processing';

                If Not FOUND Then
                    _warningMessage := format('Job %s does not have a Special_Processing entry in sw.t_job_parameters', _job);
                End If;

                If _warningMessage = '' And Not _specialProcessingText LIKE '%SourceJob:%' Then
                    _warningMessage := format('Special_Processing parameter for job %s does not contain tag "SourceJob:0000" Or "SourceJob:Auto{Sql_Where_Clause}"', _job);
                    CALL public.post_log_entry ('Debug', _warningMessage, 'Lookup_Source_Job_From_Special_Processing_Param', 'sw');
                End If;

                If _warningMessage <> '' And _showDebug Then
                    RAISE WARNING '%', _warningMessage;
                End If;

            End If;

            If _warningMessage = '' Then
                _tagName := 'SourceJob';

                CALL sw.lookup_source_job_from_special_processing_text (
                          _job,
                          _dataset,
                          _specialProcessingText,
                          _tagName,
                          _sourceJob      => _sourceJob,        -- Output
                          _autoQueryUsed  => _autoQueryUsed,    -- Output
                          _warningMessage => _warningMessage,   -- Output
                          _returnCode     => _returnCode,       -- Output
                          _previewSql     => _previewSql,
                          _autoQuerySql   => _autoQuerySql);    -- Output

                If Coalesce(_warningMessage, '') = '' Then
                    If _showDebug Then
                        RAISE INFO 'Called lookup_source_job_from_special_processing_text for job %', _job;
                        RAISE INFO 'SourceJob: %; AutoQuery used: %', _sourceJob, _autoQueryUsed;
                    End If;
                Else
                    If _showDebug Then
                        RAISE WARNING '%', _warningMessage;
                    End If;

                    CALL public.post_log_entry ('Debug', _warningMessage, 'Lookup_Source_Job_From_Special_Processing_Param', 'sw');

                    -- Override _sourceJobResultsFolder with an error message; this will force the job to fail since the input folder will not be found
                    If _warningMessage ILike '%exception%' Then
                        _sourceJobResultsFolder := 'UnknownFolder_Exception_Determining_SourceJob';
                    Else
                        If _autoQueryUsed Then
                            _sourceJobResultsFolder := 'UnknownFolder_AutoQuery_SourceJob_NoResults';
                        End If;
                    End If;
                End If;

            End If;

            If _warningMessage = '' Then

                -- Lookup the results directory for the source job

                If _showDebug Then
                    RAISE INFO 'Lookup the results folder for job % using V_Source_Analysis_Job', _sourceJob;
                End If;

                SELECT Coalesce(Results_Folder, '')
                INTO _sourceJobResultsFolder
                FROM public.V_Source_Analysis_Job
                WHERE Job = _sourceJob;

                If Not FOUND Then
                    _warningMessage := format('Source Job %s not found in V_Source_Analysis_Job', _job);

                    If _showDebug Then
                        RAISE WARNING '%', _warningMessage;
                    End If;

                Else
                    _sourceJobValid := true;
                End If;
            End If;

            -- Store the results
            --
            UPDATE Tmp_Source_Job_Folders
            SET SourceJob = _sourceJob,
                SourceJobResultsFolder = _sourceJobResultsFolder,
                SourceJob2 = NULL,
                SourceJob2Dataset = NULL,
                SourceJob2FolderPath = NULL,
                SourceJob2FolderPathArchive = NULL,
                WarningMessage = _warningMessage
            WHERE Entry_ID = _entryID;

            -- Clear the warning message
            --
            _warningMessage := '';
            _autoQueryUsed := false;
            _sourceJob2 := 0;
            _sourceJob2Dataset := '';
            _sourceJob2FolderPath := 'na';
            _sourceJob2FolderPathArchive := 'na';
            _autoQuerySql := '';

            If _sourceJobValid Then

                -------------------------------------------------
                -- Check whether a 2nd source job is defined
                -------------------------------------------------

                _tagName := 'Job2';

                CALL sw.lookup_source_job_from_special_processing_text (
                          _job,
                          _dataset,
                          _specialProcessingText,
                          _tagName,
                          _sourceJob      => _sourceJob2,       -- Output
                          _autoQueryUsed  => _autoQueryUsed,    -- Output
                          _warningMessage => _warningMessage,   -- Output
                          _returnCode     => _returnCode,       -- Output
                          _previewSql     => _previewSql,
                          _autoQuerySql   => _autoQuerySql);    -- Output

                If Coalesce(_warningMessage, '') <> '' Then
                    CALL public.post_log_entry ('Debug', _warningMessage, 'Lookup_Source_Job_From_Special_Processing_Param', 'sw');

                    -- Override _sourceJobResultsFolder with an error message; this will force the job to fail since the input folder will not be found
                    If _warningMessage ILike '%exception%' Then
                        _sourceJob2FolderPath := 'UnknownFolder_Exception_Determining_SourceJob2';
                        _sourceJobResultsFolderOverride := _sourceJob2FolderPath;
                    Else
                        If _autoQueryUsed Then
                            _sourceJob2FolderPath := 'UnknownFolder_AutoQuery_SourceJob2_NoResults';
                            _sourceJobResultsFolderOverride := _sourceJob2FolderPath;
                        End If;
                    End If;
                End If;

            End If;

            _sourceJob2 := Coalesce(_sourceJob2, 0);

            If _sourceJobValid And _sourceJob2 = _sourceJob Then
                _warningMessage := format('Source Job 1 and Source Job 2 are identical (both %s); this is not allowed and likely indicates the Special Processing parameters for determining Job2 are incorrect', _sourceJob);
                _sourceJobResultsFolderOverride := format('UnknownFolder_Job1_and_Job2_are_both_%s', _sourceJob);

                _logMessage := format('Auto-query used to lookup Job2 for job %s: %s', _job, _autoQuerySql);
                CALL public.post_log_entry ('Debug', _logMessage, 'Lookup_Source_Job_From_Special_Processing_Param', 'sw');
            End If;

            If _sourceJob2 > 0 And _warningMessage = '' Then

                -- Lookup the results directory for _sourceJob2
                --
                SELECT Dataset,
                       public.combine_paths(public.combine_paths(Dataset_Storage_Path, Dataset), Results_Folder),
                       public.combine_paths(public.combine_paths(Archive_Folder_Path, Dataset),  Results_Folder)
                INTO _sourceJob2Dataset, _sourceJob2FolderPath, _sourceJob2FolderPathArchive
                FROM public.V_Source_Analysis_Job
                WHERE Job = _sourceJob2 And Not Results_Folder Is Null;

                If Not FOUND Then
                    _warningMessage := format('Source Job #2 %s not found in DMS, or has a null value for Results_Folder', _sourceJob2);
                End If;
            End If;

            If _sourceJob2 > 0 Or _warningMessage <> '' Then
                -- Store the results
                --
                UPDATE Tmp_Source_Job_Folders
                SET SourceJob2 = _sourceJob2,
                    SourceJob2Dataset = _sourceJob2Dataset,
                    SourceJob2FolderPath = _sourceJob2FolderPath,
                    SourceJob2FolderPathArchive = _sourceJob2FolderPathArchive,
                    WarningMessage = _warningMessage
                WHERE Entry_ID = _entryID;
            End If;

            If _sourceJobResultsFolderOverride <> '' Then
                UPDATE Tmp_Source_Job_Folders
                SET SourceJobResultsFolder = _sourceJobResultsFolderOverride
                WHERE Entry_ID = _entryID;
            End If;

        EXCEPTION
            WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS
                    _sqlState         = returned_sqlstate,
                    _exceptionMessage = message_text,
                    _exceptionDetail  = pg_exception_detail,
                    _exceptionContext = pg_exception_context;

            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => _currentLocation, _logError => true);

            If Coalesce(_returnCode, '') = '' Then
                _returnCode := _sqlState;
            End If;

            _sourceJobResultsFolder := 'UnknownFolder_Exception_Determining_SourceJob';

            If _warningMessage = '' Then
                _warningMessage := 'Exception while determining source job and/or results folder';
            End If;

            UPDATE Tmp_Source_Job_Folders
            SET SourceJob = _sourceJob,
                SourceJobResultsFolder = _sourceJobResultsFolder,
                WarningMessage = _warningMessage
            WHERE Entry_ID = _entryID;

        END;

    END LOOP;

END
$$;


ALTER PROCEDURE sw.lookup_source_job_from_special_processing_param(INOUT _message text, INOUT _returncode text, IN _previewsql boolean, IN _showdebug boolean) OWNER TO d3l243;

