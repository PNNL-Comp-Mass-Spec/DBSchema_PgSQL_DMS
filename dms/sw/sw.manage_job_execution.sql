--
-- Name: manage_job_execution(text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.manage_job_execution(IN _parameters text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update table sw.t_jobs for jobs in list
**      Also call public.manage_job_execution()
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
**     Allowed values for action: state, priority, group
**
**     When the action is "state", the only allowed value is "Hold"
**     In contrast, procedure public.manage_job_execution() supports "Hold", "Release", or "Reset"
**
**  Arguments
**    _parameters   XML parameters
**    _message      Output: status or warning message
**
**  Auth:   grk
**  Date:   05/08/2009 grk - Initial release
**          09/16/2009 mem - Now updating priority and processor group directly in this DB
**                         - Next, calls manage_job_execution to update the primary DMS DB
**          05/25/2011 mem - No longer updating priority in T_Job_Steps
**          06/01/2015 mem - Removed support for option _action = 'group' because we have deprecated processor groups
**          02/15/2016 mem - Added back support for _action = 'group'
**          05/05/2023 mem - Ported to PostgreSQL
**          05/07/2023 mem - Remove unused variable
**          09/13/2023 mem - Remove unnecessary delimiter argument when calling append_to_text()
**          10/18/2023 mem - Drop temp table Tmp_JobList before exiting the procedure
**
*****************************************************/
DECLARE
    _priority text;
    _newPriority int;
    _associatedProcessorGroup text;
    _jobUpdateCount int;
    _paramXML xml;
    _action citext;
    _value citext;
    _warning text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Extract parameters from XML input
    ---------------------------------------------------

    -- Uncomment to override _parameters
    -- _parameters := '<root> <operation> <action>priority</action> <value>3</value> </operation> <jobs> <job>245023</job> <job>304378</job> <job>305663</job> <job>305680</job> <job>305689</job> <job>305696</job> <job>121917</job> <job>305677</job> <job>305692</job> <job>305701</job> </jobs> </root>';

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

    SELECT (xpath('//root/operation/action/text()', rooted_xml))[1]::text
    INTO _action
    FROM ( SELECT _paramXML as rooted_xml) Src;


    SELECT (xpath('//root/operation/value/text()', rooted_xml))[1]::text
    INTO _value
    FROM ( SELECT _paramXML as rooted_xml) Src;

    ---------------------------------------------------
    -- Create temporary table to hold list of jobs
    -- and populate it from job list
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobList (
        Job int
    );

    INSERT INTO Tmp_JobList (Job)
    SELECT XmlQ.job
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _paramXML as params
             ) Src,
             XMLTABLE('//root/jobs/job'
                      PASSING Src.params
                      COLUMNS job int PATH '.'
                              )
         ) XmlQ;

    ---------------------------------------------------
    -- See if Priority or Processor Group needs to be updated
    ---------------------------------------------------

    If _action = 'priority' Then
        ---------------------------------------------------
        -- Immediately update priorities for jobs
        ---------------------------------------------------

        _priority := _value;
        _newPriority := public.try_cast(_priority, null::int);

        If _newPriority Is Null Then
            _message := format('The new priority value is not an integer: %s', _value);
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';

            DROP TABLE Tmp_JobList;
            RETURN;
        End If;

        UPDATE sw.t_jobs J
        SET priority = _newPriority
        FROM Tmp_JobList JL
        WHERE J.Job = JL.Job AND
              J.Priority <> _newPriority;
        --
        GET DIAGNOSTICS _jobUpdateCount = ROW_COUNT;

        If _jobUpdateCount > 0 Then
            _message := format('Job priorities changed: updated %s job(s) in sw.t_jobs', _jobUpdateCount);
            CALL public.post_log_entry ('Normal', _message, 'Manage_Job_Execution', 'sw');

            _message := '';
        End If;
    End If;

    If _action = 'group' Then
        _associatedProcessorGroup := Trim(_value);

        If _associatedProcessorGroup = '' Then
            ---------------------------------------------------
            -- Immediately remove all processor group associations for jobs in Tmp_JobList
            ---------------------------------------------------

            DELETE FROM sw.t_local_job_processors
            WHERE Job In (Select Job From Tmp_JobList);
            --
            GET DIAGNOSTICS _jobUpdateCount = ROW_COUNT;

            If _jobUpdateCount > 0 Then
                _message := format('Updated sw.t_local_job_processors; UpdateCount = 0; InsertCount = 0; DeleteCount = %s', _jobUpdateCount);
                CALL public.post_log_entry ('Normal', _message, 'Manage_Job_Execution', 'sw');

                _message := '';
            End If;
        Else
            ---------------------------------------------------
            -- Need to associate jobs with a specific processor group
            --
            -- Given the complexity of the association, this needs to be done in the public schema tables,
            -- and this will happen when public.manage_job_execution is called
            ---------------------------------------------------
        End If;
    End If;

    If _action = 'state' Then
        If _value = 'Hold' Then
            ---------------------------------------------------
            -- Immediately hold the requested jobs
            ---------------------------------------------------

            UPDATE sw.t_jobs J
            SET state = 8                            -- 8=Holding
            FROM Tmp_JobList JL
            WHERE J.job = JL.job AND State <> 8;
        Else
            _warning := 'When the action is "state", the only allowed value is "Hold"';
            RAISE WARNING '%', _warning;
        End If;
    End If;

    ---------------------------------------------------
    -- Call public.manage_job_execution to update the public schema
    ---------------------------------------------------

    CALL public.manage_job_execution (
                    _parameters,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode);    -- Output

    If Coalesce(_warning, '') <> '' Then
        _message := public.append_to_text(_message, _warning);
    End If;

    DROP TABLE Tmp_JobList;
END
$$;


ALTER PROCEDURE sw.manage_job_execution(IN _parameters text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE manage_job_execution(IN _parameters text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.manage_job_execution(IN _parameters text, INOUT _message text, INOUT _returncode text) IS 'ManageJobExecution';

