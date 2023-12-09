--
-- Name: add_update_job_parameter(integer, text, text, text, boolean, text, text, boolean, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.add_update_job_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds or updates an entry in the XML parameters for a given job
**      Alternatively, use _deleteParam => true to delete the given parameter
**
**  Arguments:
**    _job              Job number
**    _section          Section name, e.g.,   JobParameters
**    _paramName        Parameter name, e.g., SourceJob
**    _value            Value for parameter _paramName in section _section
**    _deleteParam      When false, adds/updates the given parameter; when true, deletes the parameter
**    _message          Status message
**    _returnCode       Return code
**    _infoOnly         When true, preview changes
**    _showDebug        When true, set _showDebug to true when calling get_current_function_info()
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
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          06/22/2017 mem - If updating DataPackageID, also update T_Jobs
**          08/01/2017 mem - Use THROW if not authorized
**          07/20/2023 mem - Ported to PostgreSQL
**          07/28/2023 mem - Update warning message and capitalize keywords
**          08/08/2023 mem - Fix typo in warning message
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/08/2023 mem - Select a single column when using If Not Exists()
**                         - Add _showDebug procedure argument
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

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

    _showDebug := Coalesce(_showDebug, false);

    If _infoOnly Or _showDebug Then
        RAISE INFO '';
    End If;

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

    _job         := Coalesce(_job, 0);
    _section     := Trim(Coalesce(_section, ''));
    _paramName   := Trim(Coalesce(_paramName, ''));
    _value       := Coalesce(_value, '');
    _deleteParam := Coalesce(_deleteParam, false);
    _infoOnly    := Coalesce(_infoOnly, false);

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
        If Not Exists (SELECT job FROM sw.t_jobs WHERE job = _job) Then
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
        RAISE WARNING 'Function sw.add_update_job_parameter_xml() was unable to update the XML for analysis job %: %',
            _job,
            CASE WHEN Coalesce(_message, '') = '' THEN 'Unknown reason' ELSE _message END;

    ElsIf Not _infoOnly Then

        ---------------------------------------------------
        -- Update sw.t_job_parameters
        ---------------------------------------------------

        If _existingParamsFound Then
            UPDATE sw.t_job_parameters
            SET parameters = _results.updated_xml
            WHERE job = _job;
        Else
            INSERT INTO sw.t_job_parameters( job, parameters )
            VALUES (_job, _results.updated_xml);
        End If;

        If _paramName = 'DataPackageID' Then

            _dataPkgID := public.try_cast(_value, 0);

            UPDATE sw.t_jobs
            SET data_pkg_id = _dataPkgID
            WHERE job = _job;
        End If;

    End If;

END
$$;


ALTER PROCEDURE sw.add_update_job_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _showdebug boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_job_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _showdebug boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.add_update_job_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _showdebug boolean) IS 'AddUpdateJobParameter';

