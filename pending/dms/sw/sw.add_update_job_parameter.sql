--
CREATE OR REPLACE PROCEDURE sw.add_update_job_parameter
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
**  Arguments:
**    _section       Example: JobParameters
**    _paramName     Example: SourceJob
**    _value         value for parameter _paramName in section _section
**    _deleteParam   When false, adds/updates the given parameter; when true, deletes the parameter
**
**  Auth:   mem
**  Date:   03/22/2011 mem - Initial Version
**          04/04/2011 mem - Expanded Value to varchar(4000) in Tmp_job_Parameters
**          01/19/2012 mem - Now using AddUpdateJobParameterXML
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          06/22/2017 mem - If updating DataPackageID, also update T_Jobs
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _xmlParameters xml;
    _existingParamsFound boolean := false;
    _dataPkgID int;
BEGIN
    _message := '';
    _returnCode := '';

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
    -- Validate input fields
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Lookup the current parameters stored in sw.t_job_parameters for this job
    ---------------------------------------------------
    --
    SELECT parameters
    INTO _xmlParameters
    FROM sw.t_job_parameters
    WHERE job = _job;

    If FOUND Then
        _existingParamsFound := true;
    Else
        _message := 'Warning: job not found in sw.t_job_parameters';
        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;
        _xmlParameters := '';
    End If;

    ---------------------------------------------------
    -- Call add_update_job_parameter_xml to perform the work
    ---------------------------------------------------
    --
    CALL sw.add_update_job_parameter_xml (
            _xmlParameters,                  -- Input/Output
            _section,
            _paramName,
            _value,
            _deleteParam,
            _message => _message,
            _infoOnly => _infoOnly
            );

    If Not _infoOnly Then
        ---------------------------------------------------
        -- Update sw.t_job_parameters
        -- Note: Ordering by Section name but not by parameter name
        ---------------------------------------------------
        --
        If _existingParamsFound Then
            UPDATE sw.t_job_parameters
            SET parameters = _xmlParameters
            WHERE job = _job;
        Else
            INSERT INTO sw.t_job_parameters( job, parameters )
            SELECT _job, _xmlParameters
        End If;

        If _paramName = 'DataPackageID' Then

            _dataPkgID := public.try_cast(_Value, 0)

            UPDATE sw.t_jobs
            SET data_pkg_id = _dataPkgID
            WHERE job = _job;
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE sw.add_update_job_parameter IS 'AddUpdateJobParameter';
