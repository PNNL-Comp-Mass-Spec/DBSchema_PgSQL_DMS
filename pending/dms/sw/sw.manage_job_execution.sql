--
CREATE OR REPLACE PROCEDURE sw.manage_job_execution
(
    _parameters text = '',
    INOUT _result text = '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates parameters to new values for jobs in list
**      Meant to be called by job control dashboard program
**
**  Auth:   grk
**  Date:   05/08/2009 grk - Initial release
**          09/16/2009 mem - Now updating priority and processor group directly in this DB
**                         - Next, calls manage_job_execution to update the primary DMS DB
**          05/25/2011 mem - No longer updating priority in T_Job_Steps
**          06/01/2015 mem - Removed support for option _action = 'group' because we have deprecated processor groups
**          02/15/2016 mem - Added back support for _action = 'group'
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _priority text;
    _newPriority int;
    _associatedProcessorGroup text;
    _jobUpdateCount int;
    _paramXML xml;
    _action citext;
    _value citext;
BEGIN
    _message := '';
    _returnCode:= '';
    _result := '';

    ---------------------------------------------------
    -- Extract parameters from XML input
    ---------------------------------------------------

    -- Uncomment to override _parameters
    -- _parameters := '<root> <operation> <action>priority</action> <value>3</value> </operation> <jobs> <job>245023</job> <job>304378</job> <job>305663</job> <job>305680</job> <job>305689</job> <job>305696</job> <job>121917</job> <job>305677</job> <job>305692</job> <job>305701</job> </jobs> </root>';

    _paramXML := public.try_cast(_parameters, null::xml);

    If _paramXML Is Null Then
        _result := 'The _parameters argument does not have valid XML';
        RAISE WARNING '%', _result;
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
        --

        _priority := _value;
        _newPriority := public.try_cast(_priority, null::int);

        If _newPriority Is Null Then
            _result := format('The new priority value is not an integer: %s', _value);
            RAISE WARNING '%', _result;
            RETURN;
        End If;

        UPDATE sw.t_jobs
        SET priority = _newPriority
        FROM Tmp_JobList JL
        WHERE J.Job = JL.Job AND
              J.Priority <> _newPriority;
        --
        GET DIAGNOSTICS _jobUpdateCount = ROW_COUNT;

        If _jobUpdateCount > 0 Then
            _message := format('Job priorities changed: updated %s job(s) in sw.t_jobs', _jobUpdateCount);
            Call public.post_log_entry ('Normal', _message, 'Manage_Job_Execution', 'sw');

            _message := '';
        End If;
    End If;

    If _action = 'group' Then
        _associatedProcessorGroup := Trim(_value);

        If _associatedProcessorGroup = '' Then
            ---------------------------------------------------
            -- Immediately remove all processor group associations for jobs in Tmp_JobList
            ---------------------------------------------------
            --
            DELETE FROM sw.t_local_job_processors
            WHERE Job In (Select Job From Tmp_JobList);
            --
            GET DIAGNOSTICS _jobUpdateCount = ROW_COUNT;

            If _jobUpdateCount > 0 Then
                _message := format('Updated sw.t_local_job_processors; UpdateCount = 0; InsertCount = 0; DeleteCount = %s', _jobUpdateCount);
                Call public.post_log_entry ('Normal', _message, 'Manage_Job_Execution', 'sw');

                _message := '';
            End If;
        Else
            ---------------------------------------------------
            -- Need to associate jobs with a specific processor group
            -- Given the complexity of the association, this needs to be done in DMS5,
            -- and this will happen when manage_job_execution is called
            ---------------------------------------------------
        End If;
    End If;

    If _action = 'state' Then
        If _value = 'Hold' Then

            ---------------------------------------------------
            -- Immediately hold the requested jobs
            ---------------------------------------------------
            UPDATE sw.t_jobs
            SET state = 8                            -- 8=Holding
            FROM Tmp_JobList
            WHERE J.job = JL.job AND State <> 8;

        End If;
    End If;

    ---------------------------------------------------
    -- Call manage_job_execution to update the primary DMS DB
    ---------------------------------------------------

    Call public.manage_job_execution (
                    _parameters,
                    _result => _result);     -- Output

    DROP TABLE Tmp_JobList;
END
$$;

COMMENT ON PROCEDURE sw.manage_job_execution IS 'ManageJobExecution';
