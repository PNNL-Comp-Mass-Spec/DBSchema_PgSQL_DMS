--
CREATE OR REPLACE PROCEDURE sw.validate_job_server_info
(
    _job int,
    _useJobParameters boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates fields Transfer_Folder_Path and Storage_Server in T_Jobs
**
**  Arguments:
**    _useJobParameters   When non-zero, then preferentially uses T_Job_Parameters; otherwise, directly queries DMS
**
**  Auth:   mem
**  Date:   07/12/2011 mem - Initial version
**          11/14/2011 mem - Updated to support Dataset Name being blank
**          12/21/2016 mem - Use job parameter DatasetFolderName when constructing the transfer folder path
**          03/22/2023 mem - Rename job parameter to DatasetName
**          03/24/2023 mem - Capitalize job parameter TransferFolderPath
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _transferFolderPath text;
    _storageServerName text;
    _dataset text;
    _datasetFolderName text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _job := Coalesce(_job, 0);
    _useJobParameters := Coalesce(_useJobParameters, true);

    _transferFolderPath := '';
    _dataset := '';
    _datasetFolderName := '';
    _storageServerName := '';

    If _useJobParameters Then
        ---------------------------------------------------
        -- Query sw.t_job_parameters to extract out the transferFolderPath value for this job
        -- The XML we are querying looks like:
        -- <Param Section="JobParameters" Name="TransferFolderPath" Value="\\proto-9\DMS3_Xfer\"/>
        ---------------------------------------------------
        --
        SELECT Value
        INTO _transferFolderPath
        FROM sw.get_job_param_table_local ( _job )
        WHERE Name = 'TransferFolderPath';

        SELECT Value
        INTO _dataset
        FROM sw.get_job_param_table_local ( _job )
        WHERE Name IN ('DatasetName', 'DatasetNum')
        ORDER BY Name
        LIMIT 1;

        SELECT Value
        INTO _datasetFolderName
        FROM sw.get_job_param_table_local ( _job )
        WHERE Name = 'DatasetFolderName';

        If _debugMode Then
            RAISE INFO 'Job: %, TransferFolder: %, Dataset: %, Dataset Folder: %, Source: sw.t_job_parameters',
                        _job, _transferFolderPath, _dataset, _datasetFolderName, _updateCount;
        End If;
    End If;

    If Coalesce(_transferFolderPath, '') = '' Then
        ---------------------------------------------------
        -- Info not found in sw.t_job_parameters (or _useJobParameters is false)
        --
        -- Get the settings from public.t_analysis_job (and related tables) using sw.get_job_param_table,
        -- which references public.v_get_pipeline_job_parameters
        ---------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_Job_Parameters (
            Job int,
            Section text,
            Name text,
            Value text
        );

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
            RAISE INFO 'Job: %, TransferFolder: %, Dataset: %, Dataset Folder: %, Source: sw.t_job_parameters',
                        _job, _transferFolderPath, _dataset, _datasetFolderName, _updateCount;
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
            _transferFolderPath := _transferFolderPath || '\';
        End If;

        _storageServerName := public.extract_server_name(_transferFolderPath);

        UPDATE sw.t_jobs
        SET transfer_folder_path = _transferFolderPath,
            storage_server = Case When _storageServerName = ''
                             Then storage_server
                             Else _storageServerName End
        WHERE Job = _job AND
                (Coalesce(Transfer_Folder_Path, '') <> _transferFolderPath OR
                 Coalesce(Storage_Server, '') <> _storageServerName)
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO 'Job: %, TransferFolder: %, Dataset: %, Storage Server: %',
                            _job, _transferFolderPath, _dataset, _storageServerName, _updateCount;
        End If;

    Else
        _message := 'Unable to determine TransferFolderPath and/or Dataset name for job ' || _job::text;
        CALL public.post_log_entry ('Error', _message, 'Validate_Job_Server_Info', 'sw');

        _returnCode := 'U5205';

        If _debugMode Then
            RAISE ERROR '%', _message;
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE sw.validate_job_server_info IS 'ValidateJobServerInfo';
