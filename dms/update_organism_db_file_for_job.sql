--
-- Name: update_organism_db_file_for_job(integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_organism_db_file_for_job(IN _job integer, IN _fastafilename text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the Organism DB file for an analysis job, though only if the job currently has an organism DB file defined
**
**      Used by the analysis manager when it auto-changes the organism DB file to a decoy FASTA file for FragPipe or MSFragger
**
**  Arguments:
**    _job              Analysis job number
**    _fastaFileName    New FASTA file to associate with the job; typically the name end will end with _decoy.fasta
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   11/25/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _currentFastaFile citext;
    _newFastaFile citext;
    _section text;
    _msg text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job           := Coalesce(_job, 0);
    _fastaFileName := Trim(Coalesce(_fastaFileName, ''));

    If _fastaFileName = '' Then
        _message := 'FASTA file name must be specified';
        _returnCode := 'U6200';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Assure that the job exists and that it currently has an organism DB file defined
    ---------------------------------------------------

    SELECT organism_db_name
    INTO _currentFastaFile
    FROM t_analysis_job
    WHERE job = _job;

    If Not FOUND Then
        _message    := format('Job not found in t_analysis_job: %s', _job);
        _returnCode := 'U5201';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If Not _currentFastaFile LIKE '%.fasta' Then
        _message    := format('Job does not have an organism DB file defined; not associating %s with job %s', _fastaFileName, _job);
        _returnCode := 'U5202';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Assure that the new FASTA file exists in t_organism_db_file
    ---------------------------------------------------

    SELECT file_name
    INTO _newFastaFile
    FROM t_organism_db_file
    WHERE file_name = _fastaFileName::citext;

    If Not FOUND Then
        _message    := format('FASTA file not found in t_organism_db_file: %s', _fastaFileName);
        _returnCode := 'U5203';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update t_analysis_job, provided it is not already associated with the new FASTA file
    ---------------------------------------------------

    If _currentFastaFile = _newFastaFile Then
        _message := format('Job %s is already associated with %s; leaving t_analysis_job unchanged', _job, _newFastaFile);
        RAISE INFO '%', _message;
    Else
        UPDATE t_analysis_job
        SET organism_db_name = _newFastaFile,
            comment = public.append_to_text(comment, 'auto-switched FASTA file to ' || _newFastaFile)
        WHERE job = _job AND
              organism_db_name <> _newFastaFile;

        _message := format('Associated job %s with FASTA file %s', _job, _newFastaFile);
        RAISE INFO '%', _message;
    End If;

    ---------------------------------------------------
    -- Also update sw.t_job_parameters (query comes from sw.get_job_step_params_work)
    ---------------------------------------------------

    SELECT xmltable.section,
           xmltable.value
    INTO _section, _currentFastaFile
    FROM (SELECT ('<params>' || parameters::text || '</params>')::xml AS rooted_xml
          FROM sw.t_job_parameters
          WHERE sw.t_job_parameters.job = _job) Src,
                XMLTABLE('//params/Param'
                   PASSING Src.rooted_xml
                   COLUMNS section citext PATH '@Section',
                           name    citext PATH '@Name',
                           value   citext PATH '@Value')
    WHERE xmltable.name = 'LegacyFastaFileName';

    If _currentFastaFile = _newFastaFile Then
        _message := format('Pipeline parameters for job %s already have %s; leaving sw.t_job_parameters unchanged', _job, _newFastaFile);
        RAISE INFO '%', _message;
    Else
        CALL sw.add_update_job_parameter (
                _job        => _job,
                _section    => _section,
                _paramName  => 'LegacyFastaFileName',
                _value      => _newFastaFile,
                _infoOnly   => false,
                _message    => _msg,                -- Output
                _returnCode => _returnCode);        -- Output

        If _returnCode = '' Then
            _msg := format('Updated pipeline parameters for job %s to have %s', _job, _newFastaFile);
            RAISE INFO '%', _msg;
        Else
            _msg := format('Call to procedure sw.add_update_job_parameter failed with return code %s and message "%s"', _returnCode, _msg);
            RAISE WARNING '%', _msg;
        End If;

        _message := public.append_to_text(_message, _msg);
    End If;

END
$$;


ALTER PROCEDURE public.update_organism_db_file_for_job(IN _job integer, IN _fastafilename text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

