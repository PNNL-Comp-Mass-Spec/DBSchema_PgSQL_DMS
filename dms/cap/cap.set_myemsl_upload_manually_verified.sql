--
-- Name: set_myemsl_upload_manually_verified(integer, text, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.set_myemsl_upload_manually_verified(IN _job integer, IN _statusnumlist text DEFAULT ''::text, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Use this procedure to mark an ArchiveVerify or ArchiveStatusCheck capture task job step as complete
**
**      This is required when the automated processing fails, but you have
**      manually verified that the files are downloadable from MyEMSL
**
**      In particular, use this procedure if the MyEMSL status page shows an error in step 5 or 6,
**      yet the files were manually confirmed to have been successfully uploaded (via a separate job)
**
**  Arguments:
**    _statusNumList   Comma-separated list of status_num values; required only if the step tool is ArchiveStatusCheck
**
**  Auth:   mem
**  Date:   10/03/2013 mem - Initial version
**          07/13/2017 mem - Pass both StatusNumList and StatusURIList to SetMyEMSLUploadVerified
**          06/26/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**
*****************************************************/
DECLARE
    _datasetID int := 0;
    _step int := 0;
    _tool citext;
    _state int := 0;
    _analysisJobResultsFolder text := '';
    _myEMSLStateNew int := 2;
    _statusURIList text;
    _ingestStepsCompleted int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job           := Coalesce(_job, 0);
    _statusNumList := Trim(Coalesce(_statusNumList, ''));
    _infoOnly      := Coalesce(_infoOnly, true);

    If _job <= 0 Then
        _message := '_job must be positive; unable to continue';
        _returnCode := 'U5201';
        RETURN;
    End If;

    CREATE TEMP TABLE Tmp_VerifiedStatusNumTable (
        Status_Num int NOT NULL
    );

    ---------------------------------------------------
    -- Make sure the capture task job exists and has a failed ArchiveVerify step
    -- or failed ArchiveStatusCheck step
    ---------------------------------------------------

    SELECT T.Dataset_ID,
           TS.Step,
           TS.Tool,
           TS.State,
           TS.Output_Folder_Name
    INTO _datasetID, _step, _tool, _state, _analysisJobResultsFolder
    FROM cap.t_tasks T
         INNER JOIN cap.t_task_steps TS
           ON TS.Job = T.Job
    WHERE T.Job = _job AND
          TS.Tool IN ('ArchiveVerify', 'ArchiveStatusCheck') AND
          TS.State <> 5
    ORDER BY TS.Step
    LIMIT 1;

    If Not FOUND Then
        _message := format('Job %s does not have an ArchiveVerify step or ArchiveStatusCheck step', _job);
        _returnCode := 'U5202';

        DROP TABLE Tmp_VerifiedStatusNumTable;
        RETURN;
    End If;

    If Not _state In (2, 6) Then
        _message := format('The %s step for capture task job %s is in state %s; to use this procedure the state must be 2 or 6', _tool, _job, _state);
        _returnCode := 'U5203';

        DROP TABLE Tmp_VerifiedStatusNumTable;
        RETURN;
    End If;

    If _tool = 'ArchiveStatusCheck' And _statusNumList = '' Then
        _message := '_statusNumList cannot be empty when the tool is ArchiveStatusCheck';
        _returnCode := 'U5204';

        DROP TABLE Tmp_VerifiedStatusNumTable;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Perform the update
    ---------------------------------------------------

    If _infoOnly Then
        RAISE INFO '';

        SELECT format('Preview update ... Job: %s, Step: %s, Tool: %s, OldState: %s, NewState: 5',
                        Job, Step, Tool, State)
        INTO _message
        FROM cap.t_task_steps
        WHERE Job = _job AND
              Step = _step
        LIMIT 1;

        RAISE INFO '%', _message;
    Else
        UPDATE cap.t_task_steps
        SET State = 5,
            Completion_Code = 0,
            Completion_Message = '',
            Evaluation_Code = 0,
            Evaluation_Message = 'Manually verified that files were successfully uploaded'
        WHERE Job = _job AND
              Step = _step AND
              State IN (2, 6);

        If Not FOUND Then
            _message := 'Update failed; the capture task job step was not in the correct state (or was not found)';
            _returnCode := 'U5205';

            DROP TABLE Tmp_VerifiedStatusNumTable;
            RETURN;
        End If;
    End If;

    If _tool = 'ArchiveVerify' Then
        If _infoOnly Then
            RAISE INFO 'Call cap.update_myemsl_state (_datasetID=%, _analysisJobResultsFolder=''%'', _myEMSLStateNew=%)',
                          _datasetID, _analysisJobResultsFolder, _myEMSLStateNew;
        Else
            CALL public.update_myemsl_state (_datasetID, _analysisJobResultsFolder, _myEMSLStateNew);
        End If;

        DROP TABLE Tmp_VerifiedStatusNumTable;
        RETURN;
    End If;

    If _tool <> 'ArchiveStatusCheck' Then
        DROP TABLE Tmp_VerifiedStatusNumTable;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Find the Status URIs that correspond to the values in _statusNumList
    ---------------------------------------------------

    INSERT INTO Tmp_VerifiedStatusNumTable (Status_Num)
    SELECT DISTINCT Value
    FROM public.parse_delimited_integer_list(_statusNumList)
    ORDER BY Value;

    SELECT string_agg(MU.Status_URI, ', ' ORDER BY MU.Status_URI)
    INTO _statusURIList
    FROM cap.V_MyEMSL_Uploads MU
         INNER JOIN Tmp_VerifiedStatusNumTable SL
           ON MU.Status_Num = SL.Status_Num;

    SELECT MAX(ingest_steps_completed)
    INTO _ingestStepsCompleted
    FROM cap.t_myemsl_uploads
    WHERE job = _job AND Not ingest_steps_completed Is Null;

    If _infoOnly Then
        RAISE INFO 'Call set_myemsl_upload_verified _datasetID=%, _statusNumList=''%'', _statusURIList=''%'', _ingestStepsCompleted=%)',
                      _datasetID, _statusNumList, _statusURIList, _ingestStepsCompleted;
    Else
        If Not FOUND Then
            _ingestStepsCompleted := 0;
        End If;

        CALL cap.set_myemsl_upload_verified (
                    _datasetID,
                    _statusNumList,
                    _statusURIList,
                    _ingestStepsCompleted => _ingestStepsCompleted,
                    _message => _message,
                    _returnCode => _returnCode);
    End If;

    If _returnCode <> '' Then
        If _message = '' Then
            _message := 'Error in cap.set_myemsl_upload_manually_verified';
        End If;

        _message := format('%s; error code = %s', _message, _returnCode);

        CALL public.post_log_entry ('Error', _message, 'Set_MyEMSL_Upload_Manually_Verified', 'cap');
    End If;

    DROP TABLE Tmp_VerifiedStatusNumTable;
END
$$;


ALTER PROCEDURE cap.set_myemsl_upload_manually_verified(IN _job integer, IN _statusnumlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_myemsl_upload_manually_verified(IN _job integer, IN _statusnumlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.set_myemsl_upload_manually_verified(IN _job integer, IN _statusnumlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'SetMyEMSLUploadManuallyVerified';

