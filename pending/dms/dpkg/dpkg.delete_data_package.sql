--
CREATE OR REPLACE PROCEDURE dpkg.delete_data_package
(
    _packageID int,
    INOUT _message text = '',
    _infoOnly boolean = true
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Deletes the data package, including deleting rows in the associated tracking tables:
**            T_Data_Package_Analysis_Jobs
**            T_Data_Package_Datasets
**            T_Data_Package_Experiments
**            T_Data_Package_Biomaterial
**            T_Data_Package_EUS_Proposals
**
**            Use with caution!
**
**  Auth:   mem
**  Date:   04/08/2016 mem - Initial release
**          05/18/2016 mem - Log errors to T_Log_Entries
**          04/05/2019 mem - Log the data package ID, Name, first dataset, and last dataset associated with a data package
**                         - Change the default for _infoOnly to 1 (true)
**          01/20/2023 mem - Use new column names in V_Data_Package_Detail_Report
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _dataPackageName text;
    _datasetOrExperiment text := '';
    _datasetOrExperimentCount int := 0;
    _firstDatasetOrExperiment text;
    _lastDatasetOrExperiment text;
    _logMessage text;
    _sharePath text := '';
    _msgForLog text := ERROR_MESSAGE();
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _message := '';
    _infoOnly := Coalesce(_infoOnly, true);

    BEGIN TRY

        If Not Exists (SELECT * FROM dpkg.t_data_package WHERE data_pkg_id = _packageID) Then
            _message := 'Data package ' || Cast(_packageID as varchar(9)) || ' not found in dpkg.t_data_package';
            If _infoOnly Then
                Select _message AS Warning
            Else
                RAISE INFO '%', _message;
            End If;
        Else
            If _infoOnly Then
                ---------------------------------------------------
                -- Preview the data package to be deleted
                ---------------------------------------------------
                --
                SELECT ID,
                       Name,
                       Package_Type,
                       Biomaterial_Count,
                       Experiment_Count,
                       EUS_Proposal_Count,
                       Dataset_Count,
                       Analysis_Job_Count,
                       Campaign_Count,
                       Total_Item_Count,
                       State,
                       Share_Path,
                       Description,
                       Comment,
                       Owner,
                       Requester,
                       Created,
                       Last_Modified
                FROM V_Data_Package_Detail_Report
                WHERE ID = _packageID
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            Else

                ---------------------------------------------------
                -- Lookup the data package name
                ---------------------------------------------------
                --
                SELECT "package_name" INTO _dataPackageName
                FROM dpkg.t_data_package
                WHERE data_pkg_id = _packageID

                ---------------------------------------------------
                -- Find the first and last dataset in the data package
                ---------------------------------------------------
                --
                SELECT Min(dataset), INTO _firstDatasetOrExperiment
                       _lastDatasetOrExperiment = Max(dataset),
                       _datasetOrExperimentCount = Count(*)
                FROM dpkg.t_data_package_datasets
                WHERE data_pkg_id = _packageID
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                If _myRowCount > 0 Then
                    _datasetOrExperiment := 'Datasets';
                Else
                    SELECT Min(experiment), INTO _firstDatasetOrExperiment
                           _lastDatasetOrExperiment = Max(experiment),
                           _datasetOrExperimentCount = Count(*)
                    FROM dpkg.t_data_package_experiments
                    WHERE data_pkg_id = _packageID
                    --
                    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                    If _myRowCount > 0 Then
                        _datasetOrExperiment := 'Experiments';
                    End If;
                End If;

                ---------------------------------------------------
                -- Lookup the share path on Protoapps
                ---------------------------------------------------
                --

                SELECT Share_Path INTO _sharePath
                FROM V_Data_Package_Paths
                WHERE ID = _packageID

                Begin Tran

                ---------------------------------------------------
                -- Delete the associated items
                ---------------------------------------------------
                --
                Call delete_all_items_from_data_package _packageID => @packageID, _mode => 'delete', _message => @message output

                If _message <> '' Then
                    RAISE INFO '%', _message;
                    _message := '';
                End If;

                DELETE FROM dpkg.t_data_package
                WHERE data_pkg_id = _packageID
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                If _myRowCount = 0 Then
                    _message := 'No rows were deleted from dpkg.t_data_package for data package ' || Cast(_packageID as varchar(9)) || '; this is unexpected';
                Else
                    _message := 'Deleted data package ' || Cast(_packageID as varchar(9)) || ' and all associated metadata';
                End If;

                -- Log the deletion
                -- First append the data package name
                _logMessage := _message || ': ' || _dataPackageName;

                If _datasetOrExperimentCount > 0 Then
                    -- Next append the dataset or experiment names
                    _logMessage := _logMessage +;
                            '; Included ' || Cast(_datasetOrExperimentCount As text) || ' ' || _datasetOrExperiment || ': ' ||
                            Coalesce(_firstDatasetOrExperiment, '') || ' - ' || Coalesce(_lastDatasetOrExperiment, '')
                End If;

                Call post_log_entry 'Normal', _logMessage, 'DeleteDataPackage'

                Commit

                ---------------------------------------------------
                -- Display some messages
                ---------------------------------------------------
                --

                RAISE INFO '%', _message;
                RAISE INFO '%', '';
                RAISE INFO '%', 'Be sure to delete directory ' || _sharePath;

            End If;
        End If;

    END TRY
    BEGIN CATCH
        Call format_error_message _message output, _myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0 Then
            ROLLBACK TRANSACTION;
        End If;

        Call post_log_entry 'Error', _msgForLog, 'DeleteDataPackage'
    END CATCH

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return _myError

END
$$;

COMMENT ON PROCEDURE dpkg.delete_data_package IS 'DeleteDataPackage';
