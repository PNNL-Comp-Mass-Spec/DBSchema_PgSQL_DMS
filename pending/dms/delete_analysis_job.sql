--
CREATE OR REPLACE PROCEDURE public.delete_analysis_job
(
    _job text,
    _callingUser text = '',
    _infoOnly boolean = false
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes given analysis job from the analysis job table and all referencing tables
**
**  Auth:   grk
**  Date:   03/06/2001
**          06/09/2004 grk - Added delete for analysis job request reference
**          04/07/2006 grk - Eliminated job to request map table
**          02/20/2007 grk - Added code to remove any job-to-group associations
**          03/16/2007 mem - Fixed bug that required 1 or more rows be deleted from T_Analysis_Job_Processor_Group_Associations (Ticket #393)
**          02/29/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          12/31/2008 mem - Now calling sw.DeleteJob
**          02/19/2008 grk - Modified not to call broker DB (Ticket #723)
**          05/28/2015 mem - No longer deleting processor group entries
**          03/08/2017 mem - Delete jobs in the DMS_Pipeline database if they are new, holding, or failed
**          04/21/2017 mem - Added parameter _previewMode
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/27/2018 mem - Rename _previewMode to _infoOnly
**          08/18/2020 mem - Delete jobs from T_Reporter_Ion_Observation_Rates
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;
    _alterEnteredByMessage text;

    _jobID int;
    _stateID int;
    _previewData record;
    _msg text;
BEGIN
    _message := '';
    _returnCode := '';

    _job      := Trim(Coalesce(_job, ''));
    _infoOnly := Coalesce(_infoOnly, false);

    _jobID    := public.try_cast(_job, null::int);

    If _jobID is null Then
        _message := format('Job number is not numeric: %s', _job);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    -------------------------------------------------------
    -- Validate that the job exists
    -------------------------------------------------------

    If Not Exists (SELECT * FROM t_analysis_job WHERE job = _jobID) Then

        _message := format('Job not found; nothing to delete: %s', _job);

        If _infoOnly Then
            RAISE INFO '%', _message;
        Else
            RAISE WARNING '%', _message;
        End If;

        RETURN;
    End If;

    If _infoOnly Then

        SELECT J.Job,
               Tool.Analysis_Tool,
               J.Created AS Created,
               J.Dataset_ID,
               DS.Dataset,
               J.Param_File_Name,
               J.Settings_File_Name
        INTO _previewData
        FROM t_analysis_job J
             INNER JOIN PUBLIC.t_dataset DS
               ON J.dataset_id = DS.dataset_id
             INNER JOIN PUBLIC.t_analysis_tool Tool
               ON J.analysis_tool_id = Tool.analysis_tool_id
        WHERE job = _jobID;

        RAISE INFO '';
        RAISE INFO 'To be deleted:';
        RAISE INFO 'Job %, Tool %, Created %', _previewData.Job, _previewData.Analysis_Tool, _previewData.Created;
        RAISE INFO 'Dataset ID %: %', _previewData.Dataset_ID, _previewData.Dataset;
        RAISE INFO 'Parameter file: %', _previewData.Param_File_Name;
        RAISE INFO 'Settings file:  %', _previewData.Settings_File_Name;

        RETURN;
    End If;

    -------------------------------------------------------
    -- Delete the job from t_reporter_ion_observation_rates (if it exists)
    -------------------------------------------------------

    DELETE FROM t_reporter_ion_observation_rates
    WHERE job = _jobID

    -------------------------------------------------------
    -- Delete the job from t_analysis_job
    -------------------------------------------------------

    DELETE FROM t_analysis_job
    WHERE (job = _jobID)

    _message := format('Deleted analysis job %s from t_analysis_job', _jobID);

    RAISE INFO '%', _message;

    -------------------------------------------------------
    -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
    -------------------------------------------------------

    If char_length(_callingUser) > 0 Then
        _stateID := 0;

        CALL public.alter_event_log_entry_user ('public', 5, _jobID, _stateID, _callingUser, _message => _alterEnteredByMessage);
    End If;

    -------------------------------------------------------
    -- Also delete from sw.t_jobs if the state is New, Failed, or Holding
    -- Ignore any jobs with running job steps (though if the step started over 48 hours ago, ignore that job step)
    -------------------------------------------------------

    CALL sw.delete_job_if_new_or_failed (_jobID, _callingUser, _message => _msg, _infoOnly => _infoOnly);

    If char_length(_msg) > 0 Then
        public.append_to_text(_message, _msg);
    End If;

END
$$;

COMMENT ON PROCEDURE public.delete_analysis_job IS 'DeleteAnalysisJob';
