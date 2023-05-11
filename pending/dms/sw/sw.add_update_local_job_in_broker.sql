--
CREATE OR REPLACE PROCEDURE sw.add_update_local_job_in_broker
(
    INOUT _job int,
    _scriptName text,
    _datasetName text = 'na',
    _priority int,
    _jobParam text,
    _comment text,
    _ownerUsername text,
    _dataPackageID int,
    INOUT _resultsDirectoryName text,
    _mode text default 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = '',
    _debugMode boolean = false,
    _logDebugMessages boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Create or edit analysis job directly in broker database
**
**      Example contents of _jobParam
**        Note that element and attribute names are case sensitive (use Value= and not value=)
**        Default parameters for each job script are defined in the Parameters column of table T_Scripts
**
**      <Param Section="JobParameters" Name="CreateMzMLFiles" Value="False" />
**      <Param Section="JobParameters" Name="CacheFolderRootPath" Value="\\protoapps\MaxQuant_Staging" />        (or \\proto-9\MSFragger_Staging)
**      <Param Section="JobParameters" Name="DatasetName" Value="Aggregation" />
**      <Param Section="PeptideSearch" Name="ParamFileName" Value="MaxQuant_Tryp_Stat_CysAlk_Dyn_MetOx_NTermAcet_20ppmParTol.xml" />
**      <Param Section="PeptideSearch" Name="ParamFileStoragePath" Value="\\gigasax\DMS_Parameter_Files\MaxQuant" />
**      <Param Section="PeptideSearch" Name="OrganismName" Value="Homo_Sapiens" />
**      <Param Section="PeptideSearch" Name="ProteinCollectionList" Value="TBD" />
**      <Param Section="PeptideSearch" Name="ProteinOptions" Value="seq_direction=forward,filetype=fasta" />
**      <Param Section="PeptideSearch" Name="LegacyFastaFileName" Value="na" />
**
**  Arguments:
**    _jobParam             XML (as text)
**    _mode                 'add', 'update', 'reset', or 'previewAdd'
**    _debugMode            Set to true to print debug messages (the new job will not actually be created)
**    _logDebugMessages     Set to true to log debug messages in sw.T_Log_Entries (ignored if _debugMode is false)
**
**  Auth:   grk
**  Date:   08/29/2010 grk - Initial release
**          08/31/2010 grk - reset job
**          10/06/2010 grk - Check _jobParam against parameters for script
**          10/25/2010 grk - Removed creation prohibition all jobs except aggregation jobs
**          11/25/2010 mem - Added parameter _debugMode
**          07/05/2011 mem - Now updating Tool_Version_ID when resetting job steps
**          01/09/2012 mem - Added parameter _ownerPRN
**          01/19/2012 mem - Added parameter _dataPackageID
**          02/07/2012 mem - Now updating Transfer_Folder_Path after updating T_Job_Parameters
**          03/20/2012 mem - Now calling UpdateJobParamOrgDbInfoUsingDataPkg
**          03/07/2013 mem - Now calling ResetAggregationJob to reset jobs; supports resetting a job that succeeded
**                         - No longer changing job state to 20; ResetAggregationJob will update the job state
**          04/10/2013 mem - Now passing _callingUser to MakeLocalJobInBroker
**          07/23/2013 mem - Now calling PostLogEntry only once in the Catch block
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/08/2016 mem - Include job number in errors raised by RAISERROR
**          06/16/2016 mem - Add call to AddUpdateTransferPathsInParamsUsingDataPkg
**          11/08/2016 mem - Auto-define _ownerPRN if it is empty
**          11/10/2016 mem - Pass _callingUser to GetUserLoginWithoutDomain
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          07/21/2017 mem - Fix double logging of exceptions
**          08/01/2017 mem - Use THROW if not authorized
**          11/15/2017 mem - Call ValidateDataPackageForMACJob
**          03/07/2018 mem - Call AlterEnteredByUser
**          04/06/2018 mem - Allow updating comment, priority, and owner regardless of job state
**          01/21/2021 mem - Log _jobParam to T_Log_Entries when _logDebugMessages is true
**          03/10/2021 mem - Make _jobParam an input/output variable when calling VerifyJobParameters
**                         - Send _dataPackageID and _debugMode to VerifyJobParameters
**          03/15/2021 mem - Fix bug in the Catch block that changed _myError
**                         - If VerifyJobParameters returns an error, return the error message in _message
**          01/31/2022 mem - Add more print statements to aid debugging
**          04/11/2022 mem - Use varchar(4000) when populating temp table Tmp_Job_Params using _jobParamXML
**          07/01/2022 mem - Update parameter names in comments
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          03/22/2023 mem - Rename job parameter to DatasetName (in example XML)
**          03/24/2023 mem - Capitalize job parameter TransferFolderPath
**          03/25/2023 mem - Force dataset name to 'Aggregation' if using a data package
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _jobParamXML XML;
    _logErrors boolean := true;
    _result int := 0;
    _tool text := '';
    _msg text := '';
    _reset text := 'N';
    _paramsUpdated int := 0;
    _transferFolderPath text := '';
    _logEntryID int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _datasetName := Coalesce(_datasetName, 'na');
    _dataPackageID := Coalesce(_dataPackageID, 0);

    If _dataPackageID > 0 And _datasetName <> 'Aggregation' Then
        _datasetName := 'Aggregation';
    End If;

    _debugMode := Coalesce(_debugMode, false);
    _logDebugMessages := Coalesce(_logDebugMessages, false);

    _mode := Trim(Lower(Coalesce(_mode, '')));

    If _mode = 'reset' Then
        _mode := 'update';
        _reset := 'Y';
    End If;

    If _mode::citext = 'previewAdd' AND Not _debugMode Then
        _debugMode := true;
    End If;

    If _debugMode Then
        RAISE INFO '%', '';
        RAISE INFO '%', 'AddUpdateLocalJobInBroker';
        RAISE INFO '%', _jobParam;
    End If;

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

    BEGIN

        ---------------------------------------------------
        -- Does job exist
        ---------------------------------------------------

        Declare
            _id int = 0,
            _state int = 0
        --
        SELECT
            _id = job,
            _state = state
        FROM t_jobs
        WHERE job = _job

        If _mode = 'update' AND _id = 0 Then
            RAISE EXCEPTION 'Cannot update nonexistent job %', _job;
        End If;

        If _mode = 'update' AND _datasetName <> 'Aggregation' Then
            RAISE EXCEPTION 'Currently only aggregation jobs can be updated; cannot update %', _job;
        End If;

        ---------------------------------------------------
        -- Verify parameters
        ---------------------------------------------------

        If _jobParam Is Null Then
            RAISE EXCEPTION 'Web page bug: _jobParam is null for job %', _job;
        End If;

        If _jobParam = '' Then
            RAISE EXCEPTION 'Web page bug: _jobParam is empty for job %', _job;
        End If;

        -- Uncomment to log the job parameters to sw.t_log_entries
        -- exec PostLogEntry 'Debug', _jobParam, 'AddUpdateLocalJobInBroker'
        -- RETURN;

        Call sw.verify_job_parameters (
                _jobParam output,
                _scriptName,
                _dataPackageID,
                _message => _msg,
                _returnCode => _returnCode,
                _debugMode => _debugMode);

        If _returnCode <> '' Then
            _message := 'Error from VerifyJobParameters';

            If _job > 0 Then
                _message := format('%s (Job %s)', _message, _job);
            End If;

            _message := _message || ': ' || _msg;
            RAISE INFO '%', _message;

            RAISE EXCEPTION '%', _message;
        End If;

        If Coalesce(_ownerUsername, '') = '' Then
            -- Auto-define the owner
            _ownerUsername := get_user_login_without_domain(_callingUser);
        End If;

        If _mode::citext in ('add', 'previewAdd') Then
            ---------------------------------------------------
            -- Is data package set up correctly for the job?
            ---------------------------------------------------

            -- Validate scripts 'Isobaric_Labeling' and 'MAC_iTRAQ'
            Call sw.validate_data_package_for_mac_job
                                    _dataPackageID,
                                    _scriptName,
                                    _tool,                          -- Output
                                    'validate',
                                    _message => _msg,               -- Output
                                    _returnCode => _returnCode);    -- Output


            If _returnCode <> '' Then
                -- Change _logErrors to false since the error was already logged to sw.t_log_entries by ValidateDataPackageForMACJob
                _logErrors := false;

                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Update mode
        -- restricted to certain job states and limited to certain fields
        -- force reset of job?
        ---------------------------------------------------

        If _mode = 'update' Then
        --<update>

            _jobParamXML := _jobParam::XML;

            -- Update job and params
            --
            UPDATE   t_jobs
            SET      priority = _priority,
                     comment = _comment,
                     owner_username = _ownerUsername,
                     data_pkg_id = Case When _state IN (1, 4, 5) Then _dataPackageID Else data_pkg_id End
            WHERE    job = _job

            If _state IN (1, 4, 5) And _dataPackageID > 0 Then
                 CREATE TEMP TABLE Tmp_Job_Params (
                    Section citext,
                    Name citext,
                    Value citext
                );

                INSERT INTO Tmp_Job_Params
                        (Section, Name, Value)
                SELECT XmlQ.section, XmlQ.name, XmlQ.value
                FROM (
                    SELECT xmltable.*
                    FROM ( SELECT ('<params>' || _jobParamXML::text || '</params>')::xml as rooted_xml
                         ) Src,
                         XMLTABLE('//params/Param'
                                  PASSING Src.rooted_xml
                                  COLUMNS section citext PATH '@Section',
                                          name citext PATH '@Name',
                                          value citext PATH '@Value')
                     ) XmlQ;

                ---------------------------------------------------
                -- If this job has a 'DataPackageID' defined, update parameters
                --   'CacheFolderPath'
                --   'TransferFolderPath'
                --   'DataPackagePath'
                ---------------------------------------------------

                Call sw.add_update_transfer_paths_in_params_using_data_pkg (
                        _dataPackageID,
                        _paramsUpdated,         -- Output
                        _message => _message);  -- Output

                If _paramsUpdated <> 0 Then
                    -- ToDo: update this to use XMLAGG(XMLELEMENT(
                    --       Look for similar capture task code in cap.*

                    _jobParamXML := ( SELECT * FROM Tmp_Job_Params AS Param FOR XML AUTO, TYPE);
                End If;

                DROP TABLE Tmp_Job_Params;
            End If;

            If _state IN (1, 4, 5) Then
                -- Store the job parameters (as XML) in sw.t_job_parameters
                --
                UPDATE   t_job_parameters
                SET      parameters = _jobParamXML
                WHERE    job = _job

                ---------------------------------------------------
                -- Lookup the transfer folder path from the job parameters
                ---------------------------------------------------
                --

                SELECT Value
                INTO _transferFolderPath
                FROM sw.get_job_param_table_local ( _job )
                WHERE Name = 'TransferFolderPath';

                If Coalesce(_transferFolderPath, '') <> '' Then
                    UPDATE sw.t_jobs
                    SET transfer_folder_path = _transferFolderPath
                    WHERE job = _job
                End If;

                ---------------------------------------------------
                -- If a data package is defined, update entries for
                -- OrganismName, LegacyFastaFileName, ProteinOptions, and ProteinCollectionList in sw.t_job_parameters
                ---------------------------------------------------
                --
                If _dataPackageID > 0 Then
                    Call sw.update_job_param_org_db_info_using_data_pkg _job, _dataPackageID, _deleteIfInvalid => 0, _message => _message output, _callingUser => _callingUser
                End If;

                If _reset = 'Y' Then
                --<reset>

                    Call sw.reset_aggregation_job (
                            _job,
                            _infoOnly => false,
                            _message => _message);

                End If; --<reset>
            Else
                _message := 'Only updating priority, comment, and owner since job state is not New, Complete, or Failed';
            End If;

        End If; --</update>

        ---------------------------------------------------
        -- Add mode
        ---------------------------------------------------

        If _mode::citext in ('add', 'previewAdd') Then
        --<add>

            _jobParamXML := _jobParam::XML;

            If _debugMode Then
                RAISE INFO ' ';
                RAISE INFO '%', 'JobParamXML: ' || _jobParamXML::text;

                If _logDebugMessages Then
                    Call public.post_log_entry ('Debug', _jobParam, 'Add_Update_Local_Job_in_Broker', 'sw');
                End If;
            End If;

            Call sw.make_local_job_in_broker (
                    _scriptName,
                    _datasetName,
                    _priority,
                    _jobParamXML,
                    _comment,
                    _ownerUsername,
                    _dataPackageID,
                    _debugMode,
                    _logDebugMessages,
                    _job => _job,                                       -- Output
                    _resultsDirectoryName => _resultsDirectoryName,     -- Output
                    _message => _message,                               -- Output
                    _returnCode => _returnCode,                         -- Output
                    _callingUser => _callingUser);

        End If; --</add>

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);

            If char_length(Coalesce(_callingUser, '')) > 0 Then

                SELECT MAX(entry_id)
                INTO _logEntryID
                FROM sw.t_log_entries
                WHERE Position (_exceptionMessage In message) > 0 AND
                      ABS( extract(epoch FROM (CURRENT_TIMESTAMP - Entered)) ) < 15;

                If FOUND Then
                    Call alter_entered_by_user ('sw.t_log_entries', 'entry_id', _logEntryID, _callingUser, _entryDateColumnName => 'Entered');
                End If;
            End If;

        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

END
$$;

COMMENT ON PROCEDURE sw.add_update_local_job_in_broker IS 'AddUpdateLocalJobInBroker';
