--
CREATE OR REPLACE PROCEDURE sw.update_input_folder_using_special_processing_param
(
    _jobList text,
    _infoOnly boolean = false,
    _showResultsMode int = 2,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the input folder name using the SourceJob:0000 tag defined for the specified jobs
**      Only affects job steps that have Special = 'ExtractSourceJobFromComment'
**      defined in the job script
**
**  Arguments:
**    _showResultsMode   0 to not show results, 1 to show results if Tmp_Source_Job_Folders is populated; 2 to show results even if Tmp_Source_Job_Folders is not populated
**
**  Auth:   mem
**  Date:   03/21/2011 mem - Initial Version
**          03/22/2011 mem - Now calling AddUpdateJobParameter to store the SourceJob in T_Job_Parameters
**          04/04/2011 mem - Updated to use the Special_Processing param instead of the job comment
**          07/13/2012 mem - Now determining job parameters with additional items if SourceJob2 is defined: SourceJob2, SourceJob2Dataset, SourceJob2FolderPath, and SourceJob2FolderPathArchive
**          12/15/2023 mem - Ported to PostgreSQL
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
BEGIN
    _message := Coalesce(_message, '');
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
    _infoOnly := Coalesce(_infoOnly, false);
    _showResultsMode := Coalesce(_showResultsMode, 2);

    ---------------------------------------------------
    -- Parse the jobs in _jobList
    ---------------------------------------------------
    --
    INSERT INTO Tmp_JobList (job, script, Message)
    SELECT Value AS Job,
           Coalesce(J.script, '') AS Script,
           CASE WHEN J.job IS NULL THEN 'Job Number not found in sw.t_jobs' ELSE '' END
    FROM public.parse_delimited_integer_list ( _jobList, ',' ) JL
         LEFT OUTER JOIN sw.t_jobs J
           ON JL.VALUE = J.job;

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
        --
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
        -- that have Special_Instructions = 'ExtractSourceJobFromComment'
        --
        INSERT INTO Tmp_Source_Job_Folders (Job, Step)
        SELECT _job, Step
        FROM (
            SELECT xmltable.*
            FROM ( SELECT _scriptXML As ScriptXML ) Src,
                   XMLTABLE('//JobScript/Step'
                          PASSING Src.ScriptXML
                          COLUMNS step int PATH '@Number',
                                  tool citext PATH '@Tool',
                                  special_instructions citext PATH '@Special')
             ) XmlQ
        WHERE Special_Instructions = 'ExtractSourceJobFromComment'

        If Not FOUND Then
            -- Record a warning since no valid steps were found

            _warningMessage := format('Script %s for job %s does not contain a step with Special_Instructions=''ExtractSourceJobFromComment''', _script, _job);
            RAISE WARNING '%', _warningMessage;

            UPDATE Tmp_JobList
            SET Message = _warningMessage
            WHERE Job = _job;
        End If;

    END LOOP;

    If Not Exists (SELECT * FROM Tmp_Source_Job_Folders) Then
        If _showResultsMode = 2 Then
            -- Nothing to do; simply display the contents of Tmp_JobList

            -- ToDo: show the data using RAISE INFO
            SELECT *
            FROM Tmp_JobList
            ORDER BY Job
        End If;

        DROP TABLE Tmp_JobList;
        DROP TABLE Tmp_Source_Job_Folders;

        RETURN;
    End If;

    -- Lookup the SourceJob info for each job in Tmp_Source_Job_Folders
    -- This procedure examines the Special_Processing parameter for each job (in sw.t_job_parameters)
    Call sw.lookup_source_job_from_special_processing_param (_message => _message output, _previewSql => _infoOnly)

    If Not _infoOnly Then
    -- <b2>
        -- Apply the changes
        UPDATE sw.t_job_steps JS
        SET input_folder_name = SJF.SourceJobResultsFolder
        FROM Tmp_Source_Job_Folders SJF
        WHERE JS.Job = SJF.Job AND
              JS.Step_Number = SJF.Step AND
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
                Call sw.add_update_job_parameter (_job, 'JobParameters', 'SourceJob', _sourceJobText, _deleteParam => false, _infoOnly => false);
            End If;

            If Coalesce(_jobInfo.SourceJob2, 0) > 0 Then
                _sourceJobText := _jobInfo.SourceJob2::text;
                Call sw.add_update_job_parameter (_job, 'JobParameters', 'SourceJob2', _sourceJobText, _deleteParam => false, _infoOnly => false);
                Call sw.add_update_job_parameter (_job, 'JobParameters', 'SourceJob2Dataset', _jobInfo.SourceJob2Dataset, _deleteParam => false, _infoOnly => false);
                Call sw.add_update_job_parameter (_job, 'JobParameters', 'SourceJob2FolderPath', _jobInfo.SourceJob2FolderPath, _deleteParam => false, _infoOnly => false);
                Call sw.add_update_job_parameter (_job, 'JobParameters', 'SourceJob2FolderPathArchive', _jobInfo.SourceJob2FolderPathArchive, _deleteParam => false, _infoOnly => false);
            End If;

        END LOOP; -- </c>

    End If; -- </b2>

    If Not _infoOnly Then
        _actionText := 'Updated input folder to ';
    Else
        _actionText := 'Preview update of input folder to ';
    End If;

    -- Update the message field in Tmp_JobList
    UPDATE Tmp_JobList
    Set Message = _actionText || SJF.SourceJobResultsFolder
    FROM Tmp_Source_Job_Folders SJF
    WHERE JL.Job = SJF.Job AND Coalesce(SJF.SourceJobResultsFolder, '') <> '';

    If _showResultsMode > 0 Then
        -- ToDo: show the data using RAISE INFO

        SELECT JL.*,
            SJF.Step,
            SJF.SourceJob,
            SJF.SourceJobResultsFolder,
            SJF.WarningMessage
        FROM Tmp_JobList JL
            LEFT OUTER JOIN Tmp_Source_Job_Folders SJF
            ON JL.Job = SJF.Job
        ORDER BY Job
    End If;

    DROP TABLE Tmp_JobList;
    DROP TABLE Tmp_Source_Job_Folders;
END
$$;

COMMENT ON PROCEDURE sw.update_input_folder_using_special_processing_param IS 'UpdateInputFolderUsingSpecialProcessingParam';
