--
-- Name: add_update_job_parameter_temp_table(integer, text, text, text, boolean, text, text, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.add_update_job_parameter_temp_table(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds or updates an entry in the XML parameters stored in temporary table Tmp_Job_Parameters for a given job
**      Alternatively, use _deleteParam = true to delete the given parameter
**
**      This procedure is nearly identical to sw.add_update_job_parameter(), but add_update_job_parameter() updates table sw.t_job_parameters
**
**      This procedure was previously used by sw.finish_job_creation(), but is no longer used
**
**  Arguments:
**    _job              Job number (used to lookup the parameters in Tmp_Job_Parameters); if the job does not exist in Tmp_Job_Parameters, it will be added
**    _section          Section name, e.g., JobParameters
**    _paramName        Parameter name, e.g., SourceJob
**    _value            Value for parameter _paramName in section _section
**    _deleteParam      When false, adds/updates the given parameter; when true, deletes the parameter
**    _message          Status message
**    _returnCode       Return code
**    _infoOnly         When true,
**
**  Example usage:
**      CREATE TEMP TABLE Tmp_Job_Parameters (
**          Job int NOT NULL,
**          Parameters xml NULL
**      );
**
**      CALL sw.add_update_job_parameter_temp_table (2177045, 'PeptideSearch', 'ProteinCollectionList', 'M_musculus_UniProt_SPROT_2013_09_2013-09-18', _infoOnly => true);
**      CALL sw.add_update_job_parameter_temp_table (2177045, 'PeptideSearch', 'ProteinCollectionList', 'M_musculus_UniProt_SPROT_2013_09_2013-09-18', _infoOnly => false);
**      CALL sw.add_update_job_parameter_temp_table (2177045, 'PeptideSearch', 'ProteinCollectionList', 'M_musculus_UniProt_SPROT_2013_09_2013-09-18', _infoOnly => false, _deleteParam => true);
**      CALL sw.add_update_job_parameter_temp_table (2177045, 'PeptideSearch', 'ProteinCollectionList', 'M_musculus_UniProt_SPROT_2013_09_2013-09-18');
**      CALL sw.add_update_job_parameter_temp_table (2177045, 'PeptideSearch', 'ProteinOptions', 'seq_direction=forward,filetype=fasta');
**      CALL sw.add_update_job_parameter_temp_table (2177045, 'PeptideSearch', 'OrganismName', 'Mus_musculus');
**      CALL sw.add_update_job_parameter_temp_table (2177045, 'PeptideSearch', 'ParamFileName', 'MSGFPlus_Tryp_MetOx_StatCysAlk_20ppmParTol.txt');
**
**  Auth:   mem
**  Date:   03/22/2011 mem - Initial Version
**          01/19/2012 mem - Now using Add_Update_Job_Parameter_XML
**          07/28/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _xmlParameters xml;
    _results record;
    _existingParamsFound boolean := false;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Lookup the current parameters stored in Tmp_Job_Parameters for this job
    ---------------------------------------------------

    SELECT Parameters
    INTO _xmlParameters
    FROM Tmp_Job_Parameters
    WHERE Job = _job;

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
        RAISE WARNING 'Function sw.add_update_task_parameter_xml() was unable to update the XML for analysis job %: %',
            _job,
            CASE WHEN Coalesce(_message, '') = '' THEN 'Unknown reason' ELSE _message END;

    ElsIf Not _infoOnly Then

        ---------------------------------------------------
        -- Update Tmp_Job_Parameters
        ---------------------------------------------------

        If _existingParamsFound Then
            UPDATE Tmp_Job_Parameters
            SET Parameters = _results.updated_xml
            WHERE Job = _job;
        Else
            INSERT INTO Tmp_Job_Parameters( Job, Parameters )
            SELECT _job, _results.updated_xml;
        End If;

    End If;

END
$$;


ALTER PROCEDURE sw.add_update_job_parameter_temp_table(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_job_parameter_temp_table(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.add_update_job_parameter_temp_table(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'AddUpdateJobParameterTempTable';

