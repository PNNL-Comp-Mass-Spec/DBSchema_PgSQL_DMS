--
CREATE OR REPLACE PROCEDURE sw.add_update_job_parameter_temp_table
(
    _job int,
    _section text,
    _paramName text,
    _value text,
    _deleteParam boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds or updates an entry in the XML parameters for a given job
**      Alternatively, use _deleteParam = true to delete the given parameter
**
**      This procedure is nearly identical to AddUpdateJobParameter;
**      However, it operates on Tmp_Job_Parameters
**
**  Arguments:
**    _section       Example: JobParameters
**    _paramName     Example: SourceJob
**    _value         value for parameter _paramName in section _section
**    _deleteParam   When false, adds/updates the given parameter; when true, deletes the parameter
**
**  Auth:   mem
**  Date:   03/22/2011 mem - Initial Version
**          01/19/2012 mem - Now using AddUpdateJobParameterXML
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _xmlParameters xml;
    _existingParamsFound boolean := false;
BEGIN
    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _message := '';
    _returnCode:= '';
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Lookup the current parameters stored in Tmp_Job_Parameters for this job
    ---------------------------------------------------
    --
    SELECT Parameters
    INTO _xmlParameters
    FROM Tmp_Job_Parameters
    WHERE Job = _job

    If FOUND Then
        _existingParamsFound := true;
    Else
        _message := 'Warning: job not found in Tmp_Job_Parameters';
        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;
        _xmlParameters := '';
    End If;

    ---------------------------------------------------
    -- Call add_update_job_parameter_xml to perform the work
    ---------------------------------------------------
    --
    Call sw.add_update_job_parameter_xml (
            _xmlParameters output,
            _section,
            _paramName,
            _value,
            _deleteParam,
            _message => _message,
            _infoOnly => _infoOnly);

    If Not _infoOnly Then
        ---------------------------------------------------
        -- Update Tmp_Job_Parameters
        -- Note: Ordering by Section name but not by parameter name
        ---------------------------------------------------
        --
        If _existingParamsFound Then
            UPDATE Tmp_Job_Parameters
            SET Parameters = _xmlParameters
            WHERE Job = _job
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        Else
            INSERT INTO Tmp_Job_Parameters( Job, Parameters )
            SELECT _job, _xmlParameters
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE sw.add_update_job_parameter_temp_table IS 'AddUpdateJobParameterTempTable';
