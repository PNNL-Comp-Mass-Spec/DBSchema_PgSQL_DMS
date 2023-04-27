--
CREATE OR REPLACE PROCEDURE sw.get_job_step_params_xml
(
    _job int,
    _step int,
    INOUT _parameters text,
    INOUT _message text = '',
    INOUT _returnCode text = '',
    _jobIsRunningRemote int = 0,
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Get job step parameters for given job step
**
**  Note: Data comes from sw.T_Job_Parameters, not from the public tables
**
**  Arguments:
**    _parameters           Output: job step parameters (in XML)
**    _jobIsRunningRemote   RequestStepTaskXML will set this to 1 if the newly started job step was state 9
**
**  Auth:   grk
**  Date:   12/11/2008 grk - initial release
**          01/14/2009 mem - Increased the length of the Value entries extracted from T_Job_Parameters to be 2000 characters (nvarchar(4000)), Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714
**          05/29/2009 mem - Added parameter _debugMode
**          12/04/2009 mem - Moved the code that defines the job parameters to GetJobStepParamsWork
**          05/11/2017 mem - Add parameter _jobIsRunningRemote
**          05/13/2017 mem - Only add RunningRemote to Tmp_JobParamsTable if _jobIsRunningRemote is non-zero
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _st table (;
    _x xml;
    _xp text;
BEGIN

    _message := '';
    _returnCode := '';

    _parameters := '';

    ---------------------------------------------------
    -- Temporary table to hold job parameters
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_JobParamsTable (
        Section text,
        Name text,
        Value text
    )

    ---------------------------------------------------
    -- Call get_job_step_params_work to populate the temporary table
    ---------------------------------------------------

    Call sw.get_job_step_params_work (
            _job,
            _step,
            _message => _message,           -- Output
            _returnCode => _returnCode,     -- Output
            _debugMode => _debugMode);

    If _returnCode <> '' Then
        DROP TABLE Tmp_JobParamsTable;
        RETURN;
    End If;

    If (Coalesce(_jobIsRunningRemote, 0) > 0) Then
        INSERT INTO Tmp_JobParamsTable (Section, Name, Value)
        VALUES ('StepParameters', 'RunningRemote', _jobIsRunningRemote)
    End If;

    If _debugMode Then
        RAISE INFO '%, GetJobStepParamsXML: populate _st table', public.timestamp_text_immutable(clock_timestamp());
    End If;

    --------------------------------------------------------------
    -- Create XML correctly shaped into settings file format
    -- from flat parameter values table (section/item/value)
    --------------------------------------------------------------
    --
    -- Need a separate table to hold sections
    -- for outer nested 'for xml' query
    --
        name text
    )
    INSERT INTO _st( name )
    SELECT DISTINCT Section
    FROM Tmp_JobParamsTable

    If _debugMode Then
        RAISE INFO '%, GetJobStepParamsXML: populate _x xml variable', public.timestamp_text_immutable(clock_timestamp());
    End If;

    --------------------------------------------------------------
    -- Run nested query with sections as outer
    -- query and values as inner query to shape XML
    --------------------------------------------------------------
    --

    -- ToDo: update this to use XMLAGG(XMLELEMENT(
    --       Look for similar capture task code in cap.*

    _x := (;
        SELECT
          name,
          (SELECT
            Name  AS key,
            Coalesce(Value, '') AS value
           FROM
            Tmp_JobParamsTable item
           WHERE item.Section = section.name
                 AND Not item.name Is Null
           for xml auto, type
          )
        FROM
          _st section
        for xml auto, type
    )

    --------------------------------------------------------------
    -- Add XML version of all parameters to parameter list as its own parameter
    --------------------------------------------------------------
    --
    _xp := '<sections>' || _x::text || '</sections>';

    If _debugMode Then
        RAISE INFO '%, GetJobStepParamsXML: exiting', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Return parameters in XML
    ---------------------------------------------------
    --
    _parameters := _xp;

    DROP TABLE Tmp_JobParamsTable;

END
$$;

COMMENT ON PROCEDURE sw.get_job_step_params_xml IS 'GetJobStepParamsXML';
