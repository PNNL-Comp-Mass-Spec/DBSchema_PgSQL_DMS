--
CREATE OR REPLACE PROCEDURE cap.set_myemsl_upload_manually_verified
(
    _job int,
    _statusNumList text = '',
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Use this procedure to mark an ArchiveVerify capture task job step or ArchiveStatusCheck as complete
**
**      This is required when the automated processing fails, but you have
**      manually verified that the files are downloadable from MyEMSL
**
**      In particular, use this procedure if the MyEMSL status page shows an error in step 5 or 6,
**      yet the files were manually confirmed to have been successfully uploaded
**
**  Arguments:
**    _statusNumList   Required only if the step tool is ArchiveStatusCheck
**
**  Auth:   mem
**  Date:   10/03/2013 mem - Initial version
**          07/13/2017 mem - Pass both StatusNumList and StatusURIList to SetMyEMSLUploadVerified
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int := 0;
    _step int := 0;
    _tool text;
    _state int := 0;
    _outputFolderName text := '';
    _myEMSLStateNew int := 2;
    _statusURIList text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job := Coalesce(_job, 0);
    _statusNumList := Coalesce(_statusNumList, '');
    _infoOnly := Coalesce(_infoOnly, true);

    _message := '';
    _returnCode := '';

    If _job <= 0 Then
        _message := '_job must be positive; unable to continue';
        _returnCode := 'U5201';
        RETURN;
    End If;

    CREATE TEMP TABLE Tmp_VerifiedStatusNumTable (
        Status_Num int NOT NULL
    )
    ---------------------------------------------------
    -- Make sure the capture task job exists and has a failed ArchiveVerify step
    -- or failed ArchiveStatusCheck step
    ---------------------------------------------------

    SELECT T.Dataset_ID,
           TS.Step,
           TS.Tool,
           TS.State,
           TS.Output_Folder_Name
    INTO _datasetID, _step, _tool, _state, _outputFolderName
    FROM cap.t_tasks T
         INNER JOIN cap.t_task_steps TS
           ON TS.Job = T.Job
    WHERE T.Job = _job AND
          TS.Tool IN ('ArchiveVerify', 'ArchiveStatusCheck') AND
          TS.State <> 5
    ORDER BY TS.Step
    LIMIT 1;

    If Coalesce(_step, 0) = 0 Then
        _message := 'Job ' || _job::text || ' does not have an ArchiveVerify step or ArchiveStatusCheck step';
        _returnCode := 'U5202';
        RETURN;
    End If;

    If NOT _state IN (2, 6) Then
        _message := 'The ' || _tool || ' step for capture task job ' || _job::text || ' is in state ' || _state::text || '; to use this procedure the state must be 2 or 6';
        _returnCode := 'U5203';
        RETURN;
    End If;

    If _tool = 'ArchiveStatusCheck' And Trim(_statusNumList) = '' Then
        _message := '_statusNumList cannot be empty when the tool is ArchiveStatusCheck';
        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Perform the update
    ---------------------------------------------------

    If _infoOnly Then

        -- ToDo: Show this data using RAISE INFO

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
            RETURN;
        End If;
    End If;

    If _tool = 'ArchiveVerify' Then

        If _infoOnly Then

            RAISE INFO 'call cap.update_myemsl_state (_datasetID=%, _outputFolderName=''%'', _myEMSLStateNew=%)',
                          _datasetID, _outputFolderName, _myEMSLStateNew;

        Else
            call cap.update_myemsl_state (_datasetID, _outputFolderName, _myEMSLStateNew);
        End If;
    End If;

    If _tool = 'ArchiveStatusCheck' Then

        ---------------------------------------------------
        -- Find the Status URIs that correspond to the values in _statusNumList
        ---------------------------------------------------

        INSERT INTO Tmp_VerifiedStatusNumTable (Status_Num)
        SELECT DISTINCT Value
        FROM public.parse_delimited_integer_list(_statusNumList, ',')
        ORDER BY Value;

        SELECT string_agg(MU.Status_URI, ', ')
        INTO _statusURIList
        FROM cap.V_MyEMSL_Uploads MU
             INNER JOIN Tmp_VerifiedStatusNumTable SL
               ON MU.Status_Num = SL.Status_Num;

        If _infoOnly Then

            RAISE INFO 'call set_myemsl_upload_verified _datasetID=%, _statusNumList=''%'', _statusURIList=''%'')',
                          _datasetID, _statusNumList, _statusURIList;
        Else
            call cap.set_myemsl_upload_verified (_datasetID, _statusNumList, _statusURIList);
        End If;

    End If;


    If _returnCode <> '' Then
        If _message = '' Then
            _message := 'Error in set_myemsl_upload_manually_verified';
        End If;

        _message := format('%s; error code = %s', _message, _returnCode);

        call public.post_log_entry('Error', _message, 'set_myemsl_upload_manually_verified', 'cap');
    End If;

END
$$;

COMMENT ON PROCEDURE cap.set_myemsl_upload_manually_verified IS 'SetMyEMSLUploadManuallyVerified';
