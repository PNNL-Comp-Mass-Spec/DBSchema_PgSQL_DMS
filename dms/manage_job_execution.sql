--
-- Name: manage_job_execution(text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.manage_job_execution(IN _parameters text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Uses update_analysis_jobs_work() to update values in table t_analysis_job for jobs in list
**
**      Meant to be called by the Job Control Dashboard program
**
**      Example contents of _parameters:
**          <root>
**            <operation>
**              <action>priority</action>
**              <value>5</value>
**            </operation>
**            <jobs>
**              <job>1563493</job>
**              <job>1563496</job>
**              <job>1563499</job>
**            </jobs>
**          </root>
**
**      Allowed values for action: state, priority, group
**
**      When the action is "state", allowed values are "Hold", "Release", or "Reset"
**
**      When the action is "group", this procedure passses the given processor group to procedure update_analysis_jobs_work(),
**      but that procedure no longer supports processor groups, and the value will thus be ignored
**
**  Arguments:
**   _parameters    XML with jobs to update and new values
**   _message       Output message
**
**  Auth:   grk
**  Date:   07/09/2009 grk - Initial release
**          09/16/2009 mem - Updated to pass table Tmp_AnalysisJobs to update_analysis_jobs_work
**                         - Updated to resolve job state defined in the XML with t_analysis_job_state
**          05/06/2010 mem - Expanded _settingsFileName to varchar(255)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/31/2021 mem - Expand _organismName to varchar(128)
**          06/30/2022 mem - Rename parameter file argument
**          05/05/2023 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          09/01/2023 mem - Remove unnecessary cast to citext for string constants
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _jobCount int := 0;
    _paramXML xml;
    _action text;
    _value text;
    _noChangeText text;
    _state text;
    _priority text;
    _comment text;
    _findText text;
    _replaceText text;
    _assignedProcessor text;
    _associatedProcessorGroup text;
    _propagationMode text;
    _paramFileName text;
    _settingsFileName text;
    _organismName text;
    _protCollNameList text;
    _protCollOptionsList text;
    _mode text;
    _callingUser text;
    _jobList text;
BEGIN
    _message := '';
    _returnCode := '';

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

    ---------------------------------------------------
    -- Extract parameters from XML input
    ---------------------------------------------------

    _paramXML := public.try_cast(_parameters, null::xml);

    If _paramXML Is Null Then
        _message := 'The _parameters argument does not have valid XML';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Get action and value parameters
    ---------------------------------------------------

    -- Using "/." in the xpath expression would return the XML node
    -- Using "text()" means to return the text inside the <action></action> node
    -- [1] is used to select the first match (there should only be one matching node, but xpath() returns an array)

    _action := Lower((xpath('//root/operation/action/text()', _paramXML))[1]::text);

    _value  := (xpath('//root/operation/value/text()',  _paramXML))[1]::text;

    ---------------------------------------------------
    -- Create temporary table to hold list of jobs
    -- and populate it from job list
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_AnalysisJobs (
        Job int
    );

    INSERT INTO Tmp_AnalysisJobs (Job)
    SELECT public.try_cast(JobText, null::int)
    FROM (SELECT unnest(xpath('//root/jobs/job/text()', _paramXML))::text AS JobText
         ) SourceQ;
    --
    GET DIAGNOSTICS _jobCount = ROW_COUNT;

    ---------------------------------------------------
    -- Set up default arguments
    -- for calling Update_Analysis_Jobs
    ---------------------------------------------------

    _noChangeText := '[no change]';

    _state                    := _noChangeText;
    _priority                 := _noChangeText;
    _comment                  := _noChangeText;
    _findText                 := _noChangeText;
    _replaceText              := _noChangeText;
    _assignedProcessor        := _noChangeText;
    _associatedProcessorGroup := _noChangeText;
    _propagationMode          := _noChangeText;
    _paramFileName            := _noChangeText;
    _settingsFileName         := _noChangeText;
    _organismName             := _noChangeText;
    _protCollNameList         := _noChangeText;
    _protCollOptionsList      := _noChangeText;

    _mode := 'update';
    _callingUser := '';

    ---------------------------------------------------
    -- Change affected calling arguments based on
    -- command action and value
    ---------------------------------------------------

    If _action = 'state' Then
        If _value::citext = 'Hold' Then
            -- Holding;
            SELECT job_state
            INTO _state
            FROM t_analysis_job_state
            WHERE job_state_id = 8;
        End If;

        If _value::citext = 'Release' Then
            -- Release (unhold)
            SELECT job_state
            INTO _state
            FROM t_analysis_job_state
            WHERE job_state_id = 1;
        End If;

        If _value::citext = 'Reset' Then
            -- Reset
            -- For a reset, we still just Set the DMS state to 'New'
            -- If the job was failed in the broker, it will get reset
            -- If it was on hold, it will resume
            SELECT job_state
            INTO _state
            FROM t_analysis_job_state
            WHERE job_state_id = 1;
        End If;
    End If;

    If _action = 'priority' Then
        _priority := _value;
    End If;

    If _action = 'group' Then
        _associatedProcessorGroup := _value;
    End If;

    ---------------------------------------------------
    -- Call update_analysis_jobs_work function
    -- It uses Tmp_AnalysisJobs to determine which jobs to update
    ---------------------------------------------------

    CALL public.update_analysis_jobs_work (
                    _state,
                    _priority,
                    _comment,
                    _findText,
                    _replaceText,
                    _assignedProcessor,
                    _associatedProcessorGroup,
                    _propagationMode,
                    _paramFileName,
                    _settingsFileName,
                    _organismName,
                    _protCollNameList,
                    _protCollOptionsList,
                    _mode,
                    _message           => _message,         -- Output
                    _returnCode        => _returnCode,      -- Output
                    _callingUser       => _callingUser,
                    _disableRaiseError => true);

    ---------------------------------------------------
    -- Report success or error
    ---------------------------------------------------

    If _returnCode <> '' Then
        If Coalesce(_message, '') <> '' Then
            _message := format('Error: %s; %s', _message, _returnCode);
        Else
            _message := format('Unknown error calling update_analysis_jobs_work; %s', _returnCode);
        End If;
    Else
        If Coalesce(_message, '') = '' Then

            SELECT string_agg(Job, ', ' ORDER BY Job)
            INTO _jobList
            FROM Tmp_AnalysisJobs;

            _message := format('Empty message returned by update_analysis_jobs_work for action "%s" and value "%s". There were %s %s in the list: %s',
                                _action, _value, _jobCount, public.check_plural(_jobCount, 'job', 'jobs'), _jobList);
        End If;
    End If;

    DROP TABLE Tmp_AnalysisJobs;
END
$$;


ALTER PROCEDURE public.manage_job_execution(IN _parameters text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE manage_job_execution(IN _parameters text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.manage_job_execution(IN _parameters text, INOUT _message text, INOUT _returncode text) IS 'ManageJobExecution';

