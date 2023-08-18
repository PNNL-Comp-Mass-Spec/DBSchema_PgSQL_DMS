--
-- Name: delete_data_package(integer, boolean, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.delete_data_package(IN _packageid integer, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Deletes the data package, including deleting rows in the associated tracking tables:
**          dpkg.t_data_package_analysis_jobs
**          dpkg.t_data_package_datasets
**          dpkg.t_data_package_experiments
**          dpkg.t_data_package_biomaterial
**          dpkg.t_data_package_eus_proposals
**
**  Arguments:
**    _packageID    Data package ID
**    _infoOnly     When true, preview the delete
**
**  Auth:   mem
**  Date:   04/08/2016 mem - Initial release
**          05/18/2016 mem - Log errors to T_Log_Entries
**          04/05/2019 mem - Log the data package ID, Name, first dataset, and last dataset associated with a data package
**                         - Change the default for _infoOnly to 1 (true)
**          01/20/2023 mem - Use new column names in V_Data_Package_Detail_Report
**          08/15/2023 mem - Ported to PostgreSQL
**          08/17/2023 mem - Use renamed column data_pkg_id in view V_Data_Package_Paths
**
*****************************************************/
DECLARE
    _dataPackageName text;
    _datasetOrExperiment text := '';
    _datasetOrExperimentCount int := 0;
    _firstDatasetOrExperiment text;
    _lastDatasetOrExperiment text;
    _logMessage text;
    _sharePath text := '';

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);

    BEGIN

        If Not Exists (SELECT data_pkg_id FROM dpkg.t_data_package WHERE data_pkg_id = _packageID) Then
            _message := format('Data package %s not found in dpkg.t_data_package', _packageID);

            RAISE INFO '%', _message;
            RETURN;
        End If;

        If _infoOnly Then

            ---------------------------------------------------
            -- Preview the data package to be deleted
            ---------------------------------------------------

            RAISE INFO '';

            _formatSpecifier := '%-6s %-60s %-12s %-30s %-30s %-20s %-8s %-18s %-13s %-16s %-16s %-80s %-80s';

            _infoHead := format(_formatSpecifier,
                                'ID',
                                'Name',
                                'Package_Type',
                                'Owner',
                                'Requester',
                                'Created',
                                'State',
                                'Analysis_Job_Count',
                                'Dataset_Count',
                                'Experiment_Count',
                                'Total_Item_Count',
                                'Description',
                                'Comment'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '------',
                                         '------------------------------------------------------------',
                                         '------------',
                                         '------------------------------',
                                         '------------------------------',
                                         '--------------------',
                                         '--------',
                                         '------------------',
                                         '-------------',
                                         '----------------',
                                         '----------------',
                                         '--------------------------------------------------------------------------------',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT ID,
                       Name,
                       Package_Type,
                       Owner,
                       Requester,
                       Created,
                       State,
                       Analysis_Job_Count,
                       Dataset_Count,
                       Experiment_Count,
                       Total_Item_Count,
                       Description,
                       Comment
                FROM V_Data_Package_Detail_Report
                WHERE ID = _packageID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.ID,
                                    _previewData.Name,
                                    _previewData.Package_Type,
                                    _previewData.Owner,
                                    _previewData.Requester,
                                    _previewData.Created,
                                    _previewData.State,
                                    _previewData.Analysis_Job_Count,
                                    _previewData.Dataset_Count,
                                    _previewData.Experiment_Count,
                                    _previewData.Total_Item_Count,
                                    _previewData.Description,
                                    _previewData.Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Lookup the data package name
        ---------------------------------------------------

        SELECT package_name
        INTO _dataPackageName
        FROM dpkg.t_data_package
        WHERE data_pkg_id = _packageID;

        ---------------------------------------------------
        -- Find the first and last dataset in the data package
        ---------------------------------------------------

        SELECT MIN(dataset),
               MAX(dataset),
               COUNT(dataset_id)
        INTO _firstDatasetOrExperiment, _lastDatasetOrExperiment, _datasetOrExperimentCount
        FROM dpkg.t_data_package_datasets
        WHERE data_pkg_id = _packageID;

        If _datasetOrExperimentCount > 0 Then
            _datasetOrExperiment := 'Datasets';
        Else
            SELECT MIN(experiment),
                   MAX(experiment),
                   COUNT(experiment_id)
            INTO _firstDatasetOrExperiment, _lastDatasetOrExperiment, _datasetOrExperimentCount
            FROM dpkg.t_data_package_experiments
            WHERE data_pkg_id = _packageID;

            If _datasetOrExperimentCount > 0 Then
                _datasetOrExperiment := 'Experiments';
            End If;
        End If;

        ---------------------------------------------------
        -- Lookup the share path on Protoapps
        ---------------------------------------------------

        SELECT Share_Path
        INTO _sharePath
        FROM dpkg.V_Data_Package_Paths
        WHERE data_pkg_id = _packageID;

        If _infoOnly Then
            _message := format('Would delete data package %s and all associated metadata', _packageID);
        Else

            ---------------------------------------------------
            -- Delete the associated items
            ---------------------------------------------------

            CALL dpkg.delete_all_items_from_data_package (
                            _packageID => _packageID,
                            _mode => 'delete',
                            _message => _message,           -- Output
                            _returnCode => _returnCode);     -- Output

            If _message <> '' Then
                RAISE INFO '';
                RAISE INFO '%', _message;
                _message := '';
            End If;

            DELETE FROM dpkg.t_data_package
            WHERE data_pkg_id = _packageID;

            If FOUND Then
                _message := format('Deleted data package %s and all associated metadata', _packageID);
            Else
                _message := format('No rows were deleted from dpkg.t_data_package for data package %s; this is unexpected', _packageID);
            End If;
        End If;

        -- Update message to include the data package name and the first or last dataset or experiment associated with the data package
        -- First append the data package name
        _logMessage := format('%s: %s', _message, _dataPackageName);

        If _datasetOrExperimentCount > 0 Then
            -- Append the dataset or experiment counts and first/last names
            _logMessage := format('%s; %s %s %s: %s - %s',
                                _logMessage,
                                CASE WHEN _infoOnly THEN 'Including' ELSE 'Included' END,
                                _datasetOrExperimentCount,
                                _datasetOrExperiment,
                                _firstDatasetOrExperiment,
                                _lastDatasetOrExperiment);
        End If;

        If _infoOnly Then
            _message := _logMessage;

            RAISE INFO '';
            RAISE INFO '%', _message;
            RAISE INFO 'Directory to manually delete: %', _sharePath;
        Else
            -- Log the deletion
            CALL public.post_log_entry ('Normal', _logMessage, 'Delete_Data_Package', 'dpkg');

            ---------------------------------------------------
            -- Display some messages
            ---------------------------------------------------

            RAISE INFO '';
            RAISE INFO '%', _message;
            RAISE INFO '';
            RAISE INFO 'Be sure to delete directory %', _sharePath;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _exceptionMessage := format('%s; Data Package ID %s', _exceptionMessage, _packageID);

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE dpkg.delete_data_package(IN _packageid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_data_package(IN _packageid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.delete_data_package(IN _packageid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'DeleteDataPackage';

