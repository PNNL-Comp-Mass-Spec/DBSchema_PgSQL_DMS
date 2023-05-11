--
CREATE OR REPLACE PROCEDURE cap.update_missed_myemsl_state_values
(
    _windowDays int = 30,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the MyEMSLState values for datasets and/or capture task jobs
**      that have entries in T_MyEMSL_Uploads yet have
**      a MyEMSLState value of 0
**
**      This should normally not be necessary; thus, if any
**      updates are performed, we will post an error message
**      to the log
**
**  Auth:   mem
**  Date:   09/10/2013 mem - Initial version
**          12/13/2013 mem - Tweaked log message
**          02/27/2014 mem - Now updating the appropriate ArchiveUpdate capture task job if the job steps were skipped
**          03/25/2014 mem - Changed log message type to be a warning
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _windowDays := Abs(Coalesce(_windowDays, 30));
    _infoOnly := Coalesce(_infoOnly, false);

    If _windowDays < 1 Then
        _windowDays := 1;
    End If;

    ---------------------------------------------------
    -- Create a temporary table to hold the datasets or capture task jobs that need to be updated
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_IDsToUpdate (
        EntityID int NOT NULL
    )

    CREATE INDEX IX_Tmp_IDsToUpdate ON Tmp_IDsToUpdate (EntityID)

    --------------------------------------------
    -- Look for datasets that have a value of 0 for MyEMSLState
    -- and were uploaded to MyEMSL within the last _windowDays days
    --------------------------------------------
    --
    INSERT INTO Tmp_IDsToUpdate(EntityID)
    SELECT DISTINCT LookupQ.dataset_id
    FROM public.T_Dataset_Archive DA
         INNER JOIN ( SELECT dataset_id
                      FROM cap.t_myemsl_uploads
                      WHERE status_uri_path_id > 1 AND
                            entered >= CURRENT_TIMESTAMP - make_interval(0,0,0, _windowDays) AND
                            Coalesce(subfolder, '') = ''
                     ) LookupQ
           ON DA.Dataset_ID = LookupQ.dataset_id
    WHERE MyEMSL_State < 1;

    If FOUND Then
        _message := 'Found ' || _myRowCount::text || public.check_plural(_myRowCount, ' dataset that needs', ' datasets that need') || ' MyEMSLState set to 1: ';

        -- Append the dataset IDs
        SELECT string_agg(EntityID), ', ' ORDER BY EntityID)
        INTO _message
        FROM Tmp_IDsToUpdate;

        If _infoOnly Then
            RAISE INFO '%', _message;
        Else

            UPDATE public.T_Dataset_Archive
            SET MyEMSLState = 1
            WHERE AS_Dataset_ID IN (SELECT EntityID FROM Tmp_IDsToUpdate) AND
                  MyEMSLState < 1

            Call public.post_log_entry('Warning', _message, 'Update_Missed_MyEMSL_State_Values', 'cap');

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
                  Tool IN ('ArchiveVerify', 'ArchiveStatusCheck')

        End If;
    End If;

    TRUNCATE TABLE Tmp_IDsToUpdate

    --------------------------------------------
    -- Look for capture task jobs that have a value of 0 for AJ_MyEMSLState
    -- and were uploaded to MyEMSL within the last _windowDays days
    --------------------------------------------
    --
    INSERT INTO Tmp_IDsToUpdate(EntityID)
    SELECT DISTINCT T.AJ_JobID
    FROM public.T_Analysis_Job T
         INNER JOIN ( SELECT dataset_id,
                             subfolder
           FROM cap.t_myemsl_uploads
                      WHERE status_uri_path_id > 1 AND
                            entered >= CURRENT_TIMESTAMP - make_interval(0,0,0, _windowDays) AND
                            Coalesce(subfolder, '') <> ''
                     ) LookupQ
           ON T.dataset_id = LookupQ.dataset_id AND
              T.results_folder_name = LookupQ.subfolder
    WHERE T.AJ_MyEMSLState < 1

    If FOUND Then
        _message := 'Found ' || _myRowCount::text || public.check_plural(_myRowCount, ' capture task job that needs', ' capture task jobs that need') || ' MyEMSLState set to 1: ';

        -- Append the capture task job IDs
        SELECT string_agg(EntityID), ', ' ORDER BY EntityID)
        INTO _message
        FROM Tmp_IDsToUpdate;

        If _infoOnly Then
            RAISE INFO '%', _message;
        Else

            UPDATE public.T_Analysis_Job
            SET AJ_MyEMSLState = 1
            WHERE AJ_JobID IN (SELECT EntityID FROM Tmp_IDsToUpdate) AND
                  AJ_MyEMSLState < 1

            Call public.post_log_entry('Warning', _message, 'Update_Missed_MyEMSL_State_Values', 'cap');
        End If;

        -- Reset skipped ArchiveVerify steps for the datasets associated with the affected capture task jobs
        --
        UPDATE cap.t_task_steps
        SET State = 2
        FROM cap.t_myemsl_uploads U
               ON TS.job = U.job
        WHERE TS.dataset_id IN ( SELECT T.AJ_DatasetID
                                  FROM public.T_Analysis_Job T
                                       INNER JOIN Tmp_IDsToUpdate U
                                         ON T.AJ_JobID = U.EntityID ) AND
              TS.Tool IN ('ArchiveVerify') AND
              TS.State = 3 AND
              U.error_code = 0

    End If;

    DROP TABLE Tmp_IDsToUpdate;
END
$$;

COMMENT ON PROCEDURE cap.update_missed_myemsl_state_values IS 'UpdateMissedMyEMSLStateValues';
