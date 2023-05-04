--
CREATE OR REPLACE PROCEDURE public.manage_job_execution
(
    _parameters text = '',
    INOUT _result text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates parameters to new values for jobs in list
**      Meant to be called by job control dashboard program
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
**     Allowed values for action: state, priority, group
**
**  Arguments:
**   _parameters    XML with jobs to update and new values
**   _result        Output message
**
**  Auth:   grk
**  Date:   07/09/2009 grk - Initial release
**          09/16/2009 mem - Updated to pass table Tmp_AnalysisJobs to UpdateAnalysisJobsWork
**                         - Updated to resolve job state defined in the XML with t_analysis_job_state
**          05/06/2010 mem - Expanded _settingsFileName to varchar(255)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/31/2021 mem - Expand _organismName to varchar(128)
**          06/30/2022 mem - Rename parameter file argument
**
*****************************************************/
DECLARE
    _schemaName text;
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
    _message text;
    _callingUser text;
BEGIN
    _message := '';
    _returnCode := '';

    _result := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Extract parameters from XML input
    ---------------------------------------------------
    --
    _paramXML := public.try_cast(_parameters, null::xml);

    If _paramXML Is Null Then
        RAISE EXCEPTION 'Unable to convert _parameters to XML';
    End If;

    ---------------------------------------------------
    -- Get action and value parameters
    ---------------------------------------------------

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
    -- for calling UpdateAnalysisJobs
    ---------------------------------------------------
    --
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
    _message := '';
    _returnCode:= '';
    _callingUser := '';

    ---------------------------------------------------
    -- Change affected calling arguments based on
    -- command action and value
    ---------------------------------------------------
    --
    If _action = 'state' Then
        If _value::citext = 'Hold'::citext Then
            -- Holding;
            SELECT job_state
            INTO _state
            FROM t_analysis_job_state
            WHERE (job_state_id = 8)
        End If;

        If _value::citext = 'Release'::citext Then
            -- Release (unhold)
            SELECT job_state
            INTO _state
            FROM t_analysis_job_state
            WHERE (job_state_id = 1)
        End If;

        If _value::citext = 'Reset'::citext Then
            -- Reset
            -- For a reset, we still just Set the DMS state to 'New'
            -- If the job was failed in the broker, it will get reset
            -- If it was on hold, it will resume
            SELECT job_state
            INTO _state
            FROM t_analysis_job_state
            WHERE (job_state_id = 1)
        End If;
    End If;

    If _action = 'priority' Then
        _priority := _value;
    End If;

    If _action = 'group' Then
        _associatedProcessorGroup := _value;
    End If;

    ---------------------------------------------------
    -- Call UpdateAnalysisJobsWork function
    -- It uses Tmp_AnalysisJobs to determine which jobs to update
    ---------------------------------------------------
    --
    Call update_analysis_jobs_work (
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
        _message => _message,
        _returnCode => _returnCode,
        _callingUser => _callingUser,
        _disableRaiseError => true);

    ---------------------------------------------------
    -- Report success or error
    ---------------------------------------------------

    If _returnCode <> '' Then
        If Coalesce(_message, '') <> '' Then
            _result := format('Error: %s; %s', _message, _returnCode);
        Else
            _result := format('Unknown error calling UpdateAnalysisJobsWork; %s', _returnCode);
        End If;
    Else
        _result := _message;

        If Coalesce(_result, '') = '' Then
            _result := 'Empty message returned by UpdateAnalysisJobsWork.  ';
            _result := _result || 'The action was "' || _action || '".  ';
            _result := _result || 'The value was "' || _value || '".  ';
            _result := _result || 'There were ' || _jobCount::text || ' jobs in the list: ';
        End If;
    End If;

    DROP TABLE Tmp_AnalysisJobs;
END
$$;

COMMENT ON PROCEDURE public.manage_job_execution IS 'ManageJobExecution';
