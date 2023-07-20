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
**    _section          Section name, e.g.,   JobParameters
**    _paramName        Parameter name, e.g., SourceJob
**    _value            Value for parameter _paramName in section _section
**    _deleteParam      When false, adds/updates the given parameter; when true, deletes the parameter
**
**
**  Example usage:
**
**      CALL sw.add_update_job_parameter (2177045, 'PeptideSearch', 'ProteinCollectionList', 'M_musculus_UniProt_SPROT_2013_09_2013-09-18', _infoOnly => true);
**      CALL sw.add_update_job_parameter (2177045, 'PeptideSearch', 'ProteinCollectionList', 'M_musculus_UniProt_SPROT_2013_09_2013-09-18', _infoOnly => false);
**      CALL sw.add_update_job_parameter (2177045, 'PeptideSearch', 'ProteinCollectionList', 'M_musculus_UniProt_SPROT_2013_09_2013-09-18', _infoOnly => false, _deleteParam => true);
**
**  Auth:   mem
**  Date:   03/22/2011 mem - Initial Version
**          04/04/2011 mem - Expanded Value to varchar(4000) in Tmp_job_Parameters
**          01/19/2012 mem - Now using Add_Update_Job_Parameter_XML
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          06/22/2017 mem - If updating DataPackageID, also update T_Jobs
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _showDebug boolean;
    _existingParamsFound boolean = false;
    _xmlParameters xml;
    _results record;
    _dataPkgID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    _showDebug := Coalesce(_infoOnly, false);

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug);

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
    -- Validate the inputs
    ---------------------------------------------------

    _job := Coalesce(_job, 0);
    _section := Coalesce(_section, '');
    _paramName := Coalesce(_paramName, '');
    _value := Coalesce(_value, '');
    _deleteParam := Coalesce(_deleteParam, false);
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Lookup the current parameters stored in sw.t_job_parameters for this job
    ---------------------------------------------------

    SELECT parameters
    INTO _xmlParameters
    FROM sw.t_job_parameters
    WHERE job = _job;

    If FOUND Then
        _existingParamsFound := true;
    Else
        If Not Exists (Select * FROM sw.t_jobs WHERE job = _job) Then
            _message := format('Error: job %s not found in sw.t_job_parameters or sw.t_jobs', _job);

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        _message := format('Warning: job %s not found in sw.t_job_parameters, but was found in sw.t_jobs; will add a new row to sw.t_job_parameters', _job);

        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        _xmlParameters := ''::xml;
    End If;

    ---------------------------------------------------
    -- Use function add_update_job_parameter_xml to update the XML
    ---------------------------------------------------

    SELECT updated_xml, success, message
    INTO _results
    FROM sw.add_update_job_parameter_xml (
            _xmlParameters,
            _section,
            _paramName,
            _value,
            _deleteParam,
            _showDebug => _infoOnly);

    _message := _results.message;

    If Not _results.success Then
        RAISE WARNING 'Function add_update_task_parameter_xml was unable to update the XML for capture task job %: %',
            _job,
            Case When Coalesce(_message, '') = '' Then 'Unknown reason' Else _message End;

    ElsIf Not _infoOnly Then
        ---------------------------------------------------
        -- Update sw.t_job_parameters
        -- Note: Ordering by Section name but not by parameter name
        ---------------------------------------------------

        If _existingParamsFound Then
            UPDATE sw.t_job_parameters
            SET parameters = _xmlParameters
            WHERE job = _job;
        Else
            INSERT INTO sw.t_job_parameters( job, parameters )
            SELECT _job, _xmlParameters;
        End If;

        If _paramName = 'DataPackageID' Then

            _dataPkgID := public.try_cast(_value, 0)

            UPDATE sw.t_jobs
            SET data_pkg_id = _dataPkgID
            WHERE job = _job;
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE sw.add_update_job_parameter IS 'AddUpdateJobParameter';
