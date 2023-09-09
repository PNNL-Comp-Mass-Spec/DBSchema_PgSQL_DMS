--
-- Name: validate_job_server_info(integer, boolean, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.validate_job_server_info(IN _job integer, IN _usejobparameters boolean DEFAULT true, IN _debugmode boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates columns Transfer_Folder_Path and Storage_Server in sw.t_jobs
**
**  Arguments:
**    _job                  Job number
**    _useJobParameters     When non-zero, preferentially uses sw.t_job_parameters; otherwise, uses the public schema tables
**    _message              Output: status message
**    _returnCode           Output: return code
**    _debugMode            When true, show values of variables using RAISE INFO (however, sw.t_jobs will still be updated if required)
**
**  Auth:   mem
**  Date:   07/12/2011 mem - Initial version
**          11/14/2011 mem - Updated to support Dataset Name being blank
**          12/21/2016 mem - Use job parameter DatasetFolderName when constructing the transfer folder path
**          03/22/2023 mem - Rename job parameter to DatasetName
**          03/24/2023 mem - Capitalize job parameter TransferFolderPath
**          07/25/2023 mem - Ported to PostgreSQL
**          08/02/2023 mem - Move the _message and _returnCode arguments to the end of the argument list
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _createdTempTable boolean;
    _transferFolderPath text;
    _dataset text;
    _datasetFolderName text;
    _storageServerName text;
    _updateCount int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job              := Coalesce(_job, 0);
    _useJobParameters := Coalesce(_useJobParameters, true);

    _createdTempTable   := false;
    _transferFolderPath := '';
    _dataset            := '';
    _datasetFolderName  := '';
    _storageServerName  := '';

    If _useJobParameters Then
        ---------------------------------------------------
        -- Query sw.t_job_parameters to extract out the transferFolderPath value for this job
        -- The XML we are querying looks like:
        -- <Param Section="JobParameters" Name="TransferFolderPath" Value="\\proto-9\DMS3_Xfer\"/>
        ---------------------------------------------------

        SELECT Trim(Value)
        INTO _transferFolderPath
        FROM sw.get_job_param_table_local(_job)
        WHERE Name = 'TransferFolderPath';

        SELECT Value
        INTO _dataset
        FROM sw.get_job_param_table_local(_job)
        WHERE Name IN ('DatasetName', 'DatasetNum')
        ORDER BY Name
        LIMIT 1;

        SELECT Value
        INTO _datasetFolderName
        FROM sw.get_job_param_table_local(_job)
        WHERE Name = 'DatasetFolderName';

        If _debugMode Then
            RAISE INFO '';
            RAISE INFO 'Job: %, Source: sw.t_job_parameters', _job;
            RAISE INFO '  Dataset:         %', _dataset;
            RAISE INFO '  Dataset Folder:  %', _datasetFolderName;
            RAISE INFO '  Transfer Folder: %', _transferFolderPath;
        End If;
    End If;

    If Coalesce(_transferFolderPath, '') = '' Then
        ---------------------------------------------------
        -- Info not found in sw.t_job_parameters (or _useJobParameters is false)
        --
        -- Get the settings from public.t_analysis_job (and related tables) using sw.get_job_param_table(),
        -- which references public.v_get_pipeline_job_parameters
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Job_Parameters (
            Job int,
            Section text,
            Name text,
            Value text
        );

        _createdTempTable := true;

        INSERT INTO Tmp_Job_Parameters (Job, Section, Name, Value)
        SELECT job, section, name, value
        FROM sw.get_job_param_table(_job);

        SELECT Value
        INTO _transferFolderPath
        FROM Tmp_Job_Parameters
        WHERE Name = 'TransferFolderPath';

        SELECT Value
        INTO _dataset
        FROM Tmp_Job_Parameters
        WHERE Name IN ('DatasetName', 'DatasetNum')
        ORDER BY Name
        LIMIT 1;

        SELECT Value
        INTO _datasetFolderName
        FROM Tmp_job_Parameters
        WHERE Name = 'DatasetFolderName';

        If _debugMode Then
            RAISE INFO '';
            RAISE INFO 'Job: %, Source: public schema tables', _job;
            RAISE INFO '  Dataset:         %', _dataset;
            RAISE INFO '  Dataset Folder:  %', _datasetFolderName;
            RAISE INFO '  Transfer Folder: %', _transferFolderPath;
        End If;

    End If;

    If Coalesce(_transferFolderPath, '') <> '' Then
        -- Make sure transfer_folder_path and storage_server are up-to-date in sw.t_jobs
        --
        If Coalesce(_datasetFolderName, '') <> '' Then
            _transferFolderPath := public.combine_paths(_transferFolderPath, _datasetFolderName);
        Else
            If Coalesce(_dataset, '') <> '' Then
                _transferFolderPath := public.combine_paths(_transferFolderPath, _dataset);
            End If;
        End If;

        If Right(_transferFolderPath, 1) <> '\' Then
            _transferFolderPath := format('%s\', _transferFolderPath);
        End If;

        _storageServerName := sw.extract_server_name(_transferFolderPath);

        UPDATE sw.t_jobs
        SET transfer_folder_path = _transferFolderPath,
            storage_server = CASE WHEN _storageServerName = ''
                             THEN storage_server
                             ELSE _storageServerName
                             END
        WHERE Job = _job AND
              (Coalesce(Transfer_Folder_Path, '') <> _transferFolderPath OR
               Coalesce(Storage_Server, '') <> _storageServerName);
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO '  Storage Server:  %', _storageServerName;

            If _updateCount = 0 Then
                RAISE INFO '  Transfer Folder Path is already up-to-date in sw.t_jobs';
            Else
                RAISE INFO '  Updated Transfer Folder Path in sw.t_jobs for job %', _job;
            End If;
        End If;

    Else
        _message := format('Unable to determine TransferFolderPath and/or Dataset name for job %s', _job);
        CALL public.post_log_entry ('Error', _message, 'Validate_Job_Server_Info', 'sw');

        _returnCode := 'U5205';

        If _debugMode Then
            RAISE WARNING '%', _message;
        End If;

    End If;

    If _createdTempTable Then
        DROP TABLE Tmp_Job_Parameters;
    End If;
END
$$;


ALTER PROCEDURE sw.validate_job_server_info(IN _job integer, IN _usejobparameters boolean, IN _debugmode boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_job_server_info(IN _job integer, IN _usejobparameters boolean, IN _debugmode boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.validate_job_server_info(IN _job integer, IN _usejobparameters boolean, IN _debugmode boolean, INOUT _message text, INOUT _returncode text) IS 'ValidateJobServerInfo';

