--
-- Name: update_input_folder_using_special_processing_param(text, boolean, integer, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_input_folder_using_special_processing_param(IN _joblist text, IN _infoonly boolean DEFAULT false, IN _showresultsmode integer DEFAULT 2, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the input folder name using the SourceJob:0000 tag defined for the specified jobs
**
**      Only affects job steps that have 'Special="ExtractSourceJobFromComment"' defined in the job script
**
**  Arguments:
**    _jobList              Comma-separated list of jobs
**    _infoOnly             When true, preview updates; when false, update input_folder_name in t_job_steps
**    _showResultsMode      When 0, do not show results; when 1, show results if Tmp_Source_Job_Folders is populated; when 2, show results even if Tmp_Source_Job_Folders is not populated
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   03/21/2011 mem - Initial Version
**          03/22/2011 mem - Now calling Add_Update_Job_Parameter to store the SourceJob in T_Job_Parameters
**          04/04/2011 mem - Updated to use the Special_Processing param instead of the job comment
**          07/13/2012 mem - Now determining job parameters with additional items if SourceJob2 is defined: SourceJob2, SourceJob2Dataset, SourceJob2FolderPath, and SourceJob2FolderPathArchive
**          07/25/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**          10/11/2023 mem - Set _showDebug to true when calling lookup_source_job_from_special_processing_param and _infoOnly is true
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**
*****************************************************/
DECLARE
    _entryID int;
    _job int;
    _scriptXML xml;
    _script text;
    _warningMessage text;
    _actionText text;
    _jobInfo record;
    _sourceJobText text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := Trim(Coalesce(_message, ''));
    _returnCode := '';

    CREATE TEMP TABLE Tmp_JobList (
        Job int NOT NULL,
        Script text NOT NULL,
        Message text NULL
    );

    CREATE TEMP TABLE Tmp_Source_Job_Folders (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Job int NOT NULL,
        Step int NOT NULL,
        SourceJob int NULL,
        SourceJobResultsFolder text NULL,
        SourceJob2 int NULL,
        SourceJob2Dataset text NULL,
        SourceJob2FolderPath text NULL,
        SourceJob2FolderPathArchive text NULL,
        WarningMessage text NULL
    );

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly        := Coalesce(_infoOnly, false);
    _showResultsMode := Coalesce(_showResultsMode, 2);

    ---------------------------------------------------
    -- Parse the jobs in _jobList
    ---------------------------------------------------

    INSERT INTO Tmp_JobList (job, script, Message)
    SELECT Value AS Job,
           Coalesce(J.script, '') AS Script,
           CASE WHEN J.job IS NULL THEN 'Job Number not found in sw.t_jobs' ELSE '' END
    FROM public.parse_delimited_integer_list(_jobList) AS JL
         LEFT OUTER JOIN sw.t_jobs J
           ON JL.Value = J.job;

    ---------------------------------------------------
    -- Step through the jobs in Tmp_JobList
    -- and populate Tmp_Source_Job_Folders
    ---------------------------------------------------

    FOR _job, _script IN
        SELECT Job, Script
        FROM Tmp_JobList
        WHERE Script <> ''
        ORDER BY Job
    LOOP

        -- Lookup the XML for the specified script

        SELECT contents
        INTO _scriptXML
        FROM sw.t_scripts
        WHERE script = _script;

        If Not FOUND Then
            _warningMessage := format('Script for job %s not found in sw.t_scripts: %s', _job, _script);
            RAISE WARNING '%', _warningMessage;

            UPDATE Tmp_JobList
            SET Message = _warningMessage
            WHERE Job = _job;

            CONTINUE;
        End If;

        -- Add new rows to Tmp_Source_Job_Folders for any steps in the script
        -- that have Special="ExtractSourceJobFromComment"

        INSERT INTO Tmp_Source_Job_Folders (Job, Step)
        SELECT _job, Step
        FROM (
            SELECT xmltable.*
            FROM (SELECT _scriptXML AS ScriptXML ) Src,
                  XMLTABLE('//JobScript/Step'
                         PASSING Src.ScriptXML
                         COLUMNS step                 int    PATH '@Number',
                                 tool                 text   PATH '@Tool',
                                 special_instructions citext PATH '@Special')
             ) XmlQ
        WHERE Special_Instructions = 'ExtractSourceJobFromComment';

        If Not FOUND Then
            -- Record a warning since no valid steps were found
            _warningMessage := format('Script %s for job %s does not contain a step with Special_Instructions="ExtractSourceJobFromComment"', _script, _job);

            UPDATE Tmp_JobList
            SET Message = _warningMessage
            WHERE Job = _job;

            -- Only show this warning if _infoOnly is true, since sw.create_job_steps() and sw.update_job_parameters() call this procedure
            -- for all job types, not just jobs with special instructions that have 'ExtractSourceJobFromComment'
            If _infoOnly Then
                RAISE WARNING '%', _warningMessage;
            End If;
        End If;

    END LOOP;

    If Not Exists (SELECT * FROM Tmp_Source_Job_Folders) Then
        If _showResultsMode = 2 Then

            -- Nothing to do; simply display the contents of Tmp_JobList

            RAISE INFO '';

            _formatSpecifier := '%-9s %-35s %-70s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Script',
                                'Message'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---------',
                                         '-----------------------------------',
                                         '----------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Job,
                       Script,
                       Message
                FROM Tmp_JobList
                ORDER BY Job
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Job,
                                    _previewData.Script,
                                    _previewData.Message
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        DROP TABLE Tmp_JobList;
        DROP TABLE Tmp_Source_Job_Folders;

        RETURN;
    End If;

    -- Lookup the SourceJob info for each job in Tmp_Source_Job_Folders
    -- This procedure examines the Special_Processing parameter for each job (in sw.t_job_parameters)
    CALL sw.lookup_source_job_from_special_processing_param (
                _message    => _message,        -- Output
                _returnCode => _returnCode,     -- Output
                _previewSql => _infoOnly,
                _showDebug  => _infoOnly);

    If Not _infoOnly Then

        -- Apply the changes
        UPDATE sw.t_job_steps JS
        SET input_folder_name = SJF.SourceJobResultsFolder
        FROM Tmp_Source_Job_Folders SJF
        WHERE JS.Job = SJF.Job AND
              JS.Step = SJF.Step AND
              Coalesce(SJF.SourceJobResultsFolder, '') <> '';

        -- Update the parameters for each job in Tmp_Source_Job_Folders

        FOR _jobInfo IN
            SELECT Job,
                   SourceJob,
                   SourceJob2,
                   SourceJob2Dataset,
                   SourceJob2FolderPath,
                   SourceJob2FolderPathArchive
            FROM Tmp_Source_Job_Folders
            ORDER BY Job, Step
        LOOP

            If Coalesce(_jobInfo.SourceJob, 0) > 0 Then
                _sourceJobText := _jobInfo.SourceJob::text;
                CALL sw.add_update_job_parameter (_job, 'JobParameters', 'SourceJob', _sourceJobText, _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
            End If;

            If Coalesce(_jobInfo.SourceJob2, 0) > 0 Then
                _sourceJobText := _jobInfo.SourceJob2::text;
                CALL sw.add_update_job_parameter (_job, 'JobParameters', 'SourceJob2', _sourceJobText,                                        _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
                CALL sw.add_update_job_parameter (_job, 'JobParameters', 'SourceJob2Dataset', _jobInfo.SourceJob2Dataset,                     _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
                CALL sw.add_update_job_parameter (_job, 'JobParameters', 'SourceJob2FolderPath', _jobInfo.SourceJob2FolderPath,               _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
                CALL sw.add_update_job_parameter (_job, 'JobParameters', 'SourceJob2FolderPathArchive', _jobInfo.SourceJob2FolderPathArchive, _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
            End If;

        END LOOP;

    End If;

    If Not _infoOnly Then
        _actionText := 'Updated input folder to ';
    Else
        _actionText := 'Preview update of input folder to ';
    End If;

    -- Update the message field in Tmp_JobList
    UPDATE Tmp_JobList JL
    SET Message = format('%s%s', _actionText, SJF.SourceJobResultsFolder)
    FROM Tmp_Source_Job_Folders SJF
    WHERE JL.Job = SJF.Job AND Coalesce(SJF.SourceJobResultsFolder, '') <> '';

    If _showResultsMode > 0 Then

        RAISE INFO '';

        _formatSpecifier := '%-9s %-35s %-70s %-4s %-10s %-35s %-100s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Script',
                            'Message',
                            'Step',
                            'Source_Job',
                            'Source_Job_Results_Folder',
                            'Warning_Message'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '-----------------------------------',
                                     '----------------------------------------------------------------------',
                                     '----',
                                     '----------',
                                     '-----------------------------------',
                                     '----------------------------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT JL.Job,
                   JL.Script,
                   JL.Message,
                   SJF.Step,
                   SJF.SourceJob AS Source_Job,
                   SJF.SourceJobResultsFolder AS Source_Job_Results_Folder,
                   SJF.WarningMessage AS Warning_Message
            FROM Tmp_JobList JL
                LEFT OUTER JOIN Tmp_Source_Job_Folders SJF
                ON JL.Job = SJF.Job
            ORDER BY Job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Script,
                                _previewData.Message,
                                _previewData.Step,
                                _previewData.Source_Job,
                                _previewData.Source_Job_Results_Folder,
                                _previewData.Warning_Message
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    DROP TABLE Tmp_JobList;
    DROP TABLE Tmp_Source_Job_Folders;
END
$$;


ALTER PROCEDURE sw.update_input_folder_using_special_processing_param(IN _joblist text, IN _infoonly boolean, IN _showresultsmode integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_input_folder_using_special_processing_param(IN _joblist text, IN _infoonly boolean, IN _showresultsmode integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_input_folder_using_special_processing_param(IN _joblist text, IN _infoonly boolean, IN _showresultsmode integer, INOUT _message text, INOUT _returncode text) IS 'UpdateInputFolderUsingSpecialProcessingParam';

