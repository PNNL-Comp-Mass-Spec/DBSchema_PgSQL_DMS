--
-- Name: update_missed_myemsl_state_values(integer, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_missed_myemsl_state_values(IN _windowdays integer DEFAULT 30, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the MyEMSL State values for datasets and/or analysis jobs
**      that have entries in cap.t_myemsl_uploads, yet have a MyEMSL_State value of 0
**
**      This should normally not be necessary; thus, if any updates are performed,
**      the procedure logs an error message
**
**  Arguments:
**    _windowDays       Threshold for the entered column in cap.t_myemsl_uploads
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   09/10/2013 mem - Initial version
**          12/13/2013 mem - Tweaked log message
**          02/27/2014 mem - Now updating the appropriate ArchiveUpdate capture task job if the job steps were skipped
**          03/25/2014 mem - Changed log message type to be a warning
**          06/29/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _matchCount int;
    _idList text;
    _jobMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _windowDays := Abs(Coalesce(_windowDays, 30));
    _infoOnly   := Coalesce(_infoOnly, false);

    If _windowDays < 1 Then
        _windowDays := 1;
    End If;

    ---------------------------------------------------
    -- Create a temporary table to hold the datasets or analysis jobs that need to be updated
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_IDsToUpdate (
        EntityID int NOT NULL
    );

    CREATE INDEX IX_Tmp_IDsToUpdate ON Tmp_IDsToUpdate (EntityID);

    --------------------------------------------
    -- Look for datasets that have a value of 0 for MyEMSL_State
    -- and were uploaded to MyEMSL within the last _windowDays days
    --------------------------------------------

    INSERT INTO Tmp_IDsToUpdate(EntityID)
    SELECT DISTINCT LookupQ.dataset_id
    FROM public.t_dataset_archive DA
         INNER JOIN ( SELECT dataset_id
                      FROM cap.t_myemsl_uploads
                      WHERE status_uri_path_id > 1 AND
                            entered >= CURRENT_TIMESTAMP - make_interval(days => _windowDays) AND
                            Coalesce(subfolder, '') = ''
                     ) LookupQ
           ON DA.Dataset_ID = LookupQ.dataset_id
    WHERE DA.MyEMSL_State < 1;
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _matchCount = 0 Then
        _jobMessage := '';
    Else

        -- Construct the list of dataset IDs
        SELECT string_agg(EntityID::text, ', ' ORDER BY EntityID)
        INTO _idList
        FROM Tmp_IDsToUpdate;

        _jobMessage := format('Found %s %s MyEMSL_State set to 1: %s',
                              _matchCount,
                              public.check_plural(_matchCount, 'dataset that needs', 'datasets that need'),
                              _idList);

        If _infoOnly Then
            RAISE INFO '%', _jobMessage;
        Else
            UPDATE public.t_dataset_archive
            SET MyEMSL_State = 1
            WHERE Dataset_ID IN (SELECT EntityID FROM Tmp_IDsToUpdate) AND
                  MyEMSL_State < 1;

            CALL public.post_log_entry ('Warning', _jobMessage, 'Update_Missed_MyEMSL_State_Values', 'cap');

            -- Reset skipped ArchiveVerify steps for the affected datasets
            --
            UPDATE cap.t_task_steps
            SET State = 2
            WHERE job IN ( SELECT M.job
                           FROM cap.t_myemsl_uploads M
                                INNER JOIN Tmp_IDsToUpdate U
                                  ON M.dataset_id = U.EntityID
                           WHERE M.error_code = 0 ) AND
                  State = 3 AND
                  Tool IN ('ArchiveVerify', 'ArchiveStatusCheck');

        End If;
    End If;

    TRUNCATE TABLE Tmp_IDsToUpdate;

    --------------------------------------------
    -- Look for analysis jobs that have a value of 0 for myemsl_state
    -- and were uploaded to MyEMSL within the last _windowDays days
    --------------------------------------------

    INSERT INTO Tmp_IDsToUpdate(EntityID)
    SELECT DISTINCT J.Job
    FROM public.t_analysis_job J
         INNER JOIN ( SELECT dataset_id,
                             subfolder
           FROM cap.t_myemsl_uploads
                      WHERE status_uri_path_id > 1 AND
                            entered >= CURRENT_TIMESTAMP - make_interval(days => _windowDays) AND
                            Coalesce(subfolder, '') <> ''
                     ) LookupQ
           ON J.dataset_id = LookupQ.dataset_id AND
              J.results_folder_name = LookupQ.subfolder
    WHERE J.myemsl_state < 1;
     --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _matchCount = 0 Then
        _message := _jobMessage;
    Else

        -- Construct the list of analysis job numbers
        SELECT string_agg(EntityID::text, ', ' ORDER BY EntityID)
        INTO _idList
        FROM Tmp_IDsToUpdate;

        _message := format('Found %s %s MyEMSL_State set to 1: %s',
                            _matchCount,
                            public.check_plural(_matchCount, 'analysis job that needs', 'analysis jobs that need'),
                            _idList);

        If _infoOnly Then
            RAISE INFO '%', _message;
        Else
            UPDATE public.t_analysis_job
            SET myemsl_state = 1
            WHERE job IN (SELECT EntityID FROM Tmp_IDsToUpdate) AND
                  myemsl_state < 1;

            CALL public.post_log_entry ('Warning', _message, 'Update_Missed_MyEMSL_State_Values', 'cap');

            -- Reset skipped ArchiveVerify steps for the datasets associated with the affected analysis jobs
            --
            UPDATE cap.t_task_steps
            SET State = 2
            FROM cap.t_myemsl_uploads U
            WHERE cap.t_task_steps.job = U.job AND
                  U.dataset_id IN ( SELECT J.dataset_id
                                    FROM public.t_analysis_job J
                                         INNER JOIN Tmp_IDsToUpdate U
                                           ON J.job = U.EntityID ) AND
                  cap.t_task_steps.Tool IN ('ArchiveVerify') AND
                  cap.t_task_steps.State = 3 AND
                  U.error_code = 0;
        End If;

        _message := public.append_to_text(_jobMessage, _message);

    End If;

    DROP TABLE Tmp_IDsToUpdate;
END
$$;


ALTER PROCEDURE cap.update_missed_myemsl_state_values(IN _windowdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_missed_myemsl_state_values(IN _windowdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_missed_myemsl_state_values(IN _windowdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateMissedMyEMSLStateValues';

