--
-- Name: delete_analysis_job(text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_analysis_job(IN _job text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete the given analysis job from t_analysis_job and all related tables
**
**  Arguments:
**    _job              Analysis job (as text) to delete
**    _infoOnly         When true, preview the deletes
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
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
**          02/02/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;
    _targetType int;
    _alterEnteredByMessage text;

    _jobID int;
    _stateID int;
    _previewData record;
    _msg text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    -------------------------------------------------
    -- Validate the inputs
    -------------------------------------------------

    _job         := Trim(Coalesce(_job, ''));
    _infoOnly    := Coalesce(_infoOnly, false);
    _callingUser := Trim(Coalesce(_callingUser, ''));

    _jobID := public.try_cast(_job, null::int);

    If _jobID Is Null Then
        _message := format('Job number is not numeric: %s', _job);

        RAISE INFO '';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    -------------------------------------------------
    -- Validate that the job exists
    -------------------------------------------------

    If Not Exists (SELECT job FROM t_analysis_job WHERE job = _jobID) Then

        _message := format('Job not found; nothing to delete: %s', _job);

        RAISE INFO '';

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
        RAISE INFO 'To be deleted:  %', format('%s job %s', _previewData.Analysis_Tool, _previewData.Job);
        RAISE INFO 'Created:        %', public.timestamp_text(_previewData.Created);
        RAISE INFO 'Dataset ID:     %', _previewData.Dataset_ID;
        RAISE INFO 'Dataset:        %', _previewData.Dataset;
        RAISE INFO 'Parameter file: %', _previewData.Param_File_Name;
        RAISE INFO 'Settings file:  %', _previewData.Settings_File_Name;

    Else
        -------------------------------------------------
        -- Delete job from t_reporter_ion_observation_rates (if it exists)
        -------------------------------------------------

        DELETE FROM t_reporter_ion_observation_rates
        WHERE job = _jobID;

        -------------------------------------------------
        -- Delete job from t_analysis_job
        -------------------------------------------------

        DELETE FROM t_analysis_job
        WHERE job = _jobID;

        _message := format('Deleted analysis job %s from t_analysis_job', _jobID);

        RAISE INFO '';
        RAISE INFO '%', _message;

        -------------------------------------------------
        -- If _callingUser is defined, call alter_event_log_entry_user to alter the entered_by field in t_event_log
        -------------------------------------------------

        If _callingUser <> '' Then
            _targetType := 5;
            _stateID := 0;

            CALL public.alter_event_log_entry_user ('public', _targetType, _jobID, _stateID, _callingUser, _message => _alterEnteredByMessage);
        End If;

    End If;

    -------------------------------------------------
    -- Also delete from sw.t_jobs if the state is New, Failed, or Holding
    -- Ignore any jobs with running job steps (though if the step started over 48 hours ago, ignore that job step)
    -------------------------------------------------

    If Exists (SELECT Job FROM sw.t_jobs WHERE job = _jobID) Then
        CALL sw.delete_job_if_new_or_failed (
                    _job         => _jobID,
                    _message     => _msg,
                    _returnCode  => _returnCode,
                    _callingUser => _callingUser,
                    _infoOnly    => _infoOnly);

        If Coalesce(_msg, '') <> '' Then
            _message := public.append_to_text(_message, _msg);
        End If;
    End If;

END
$$;


ALTER PROCEDURE public.delete_analysis_job(IN _job text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_analysis_job(IN _job text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_analysis_job(IN _job text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DeleteAnalysisJob';

