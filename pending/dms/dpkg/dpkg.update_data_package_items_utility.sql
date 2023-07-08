--
CREATE OR REPLACE PROCEDURE dpkg.update_data_package_items_utility
(
    _comment text,
    _mode text = 'add',
    _removeParents int default 0,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text default '',
    _infoOnly boolean default false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates data package items in list according to command mode
**      Expects list of items to be in temp table Tmp_DataPackageItems
**
**      CREATE TEMP TABLE Tmp_DataPackageItems (
**          DataPackageID int not null,   -- Data package ID
**          ItemType   citext null,       -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
**          Identifier citext null        -- Job ID, Dataset Name or ID, Experiment Name, Cell_Culture Name, or EUSProposal ID
**      )
**
**  Arguments:
**    _mode            'add', 'comment', 'delete'
**    _removeParents   When 1, remove parent datasets and experiments for affected jobs (or experiments for affected datasets)
**
**  Auth:   grk
**  Date:   05/23/2010
**          06/10/2009 grk - Changed size of item list to max
**          06/10/2009 mem - Now calling Update_Data_Package_Item_Counts to update the data package item counts
**          10/01/2009 mem - Now populating Campaign in T_Data_Package_Biomaterial
**          12/31/2009 mem - Added DISTINCT keyword to the INSERT INTO queries in case the source views include some duplicate rows (in particular, V_Experiment_Detail_Report_Ex)
**          05/23/2010 grk - Create this sproc from common function factored out of UpdateDataPackageItems and UpdateDataPackageItemsXML
**          12/31/2013 mem - Added support for EUS Proposals
**          09/02/2014 mem - Updated to remove non-numeric items when working with analysis jobs
**          10/28/2014 mem - Added support for adding datasets using dataset IDs; to delete datasets, you must use the dataset name (safety feature)
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          05/18/2016 mem - Fix bug removing duplicate analysis jobs
**                         - Add parameter _infoOnly
**          10/19/2016 mem - Update Tmp_DataPackageItems to use an integer field for data package ID
**                         - Call update_data_package_eus_info
**                         - Prevent addition of Biomaterial '(none)'
**          11/14/2016 mem - Add parameter _removeParents
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          04/25/2018 mem - Populate column Dataset_ID in T_Data_Package_Analysis_Jobs
**          06/12/2018 mem - Send _maxLength to append_to_text
**          07/17/2019 mem - Remove .raw and .d from the end of dataset names
**          07/02/2021 mem - Update the package comment for any existing items when _mode is 'add' and _comment is not an empty string
**          07/02/2021 mem - Change the default value for _mode from undefined mode 'update' to 'add'
**          07/06/2021 mem - Add support for dataset IDs when _mode is 'comment' or 'delete'
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          05/18/2022 mem - Use new EUS Proposal column name
**          06/08/2022 mem - Rename package comment field to Package_Comment
**          07/08/2022 mem - Use new synonym name for experiment biomaterial view
**          04/04/2023 mem - When adding datasets, do not add data package placeholder datasets (e.g. dataset DataPackage_3442_TestData)
**          05/19/2023 mem - When adding analysis jobs, do not add data package placeholder datasets
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _deleteCount int;
    _updateCount int;
    _insertCount int;
    _itemCountChanged int := 0;
    _createdDataPackageDatasetsTable boolean := false;

    _actionMsg text;
    _datasetsRemoved text;
    _packageID int;
    _dataPackageList text := '';

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

    --------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        CREATE TEMP TABLE Tmp_DatasetIDsToAdd (
            DataPackageID int NOT NULL,
            DatasetID int NOT NULL
        );

        CREATE TEMP TABLE Tmp_JobsToAddOrDelete (
            DataPackageID int not null,            -- Data package ID
            Job int not null
        );

        CREATE INDEX IX_Tmp_JobsToAddOrDelete ON Tmp_JobsToAddOrDelete (Job, DataPackageID)

        -- If working with analysis jobs, populate Tmp_JobsToAddOrDelete with all numeric job entries
        --
        If Exists ( SELECT * FROM Tmp_DataPackageItems WHERE ItemType = 'Job' ) Then
            DELETE Tmp_DataPackageItems
            WHERE Coalesce(Identifier, '') = '' OR try_cast(Identifier, null::int) Is Null;
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _infoOnly And _deleteCount > 0 Then
                RAISE INFO 'Warning: deleted % job(s) that were not numeric', _deleteCount;
            End If;

            INSERT INTO Tmp_JobsToAddOrDelete( DataPackageID, Job )
            SELECT DataPackageID,
                   Job
            FROM ( SELECT DataPackageID,
                          try_cast(Identifier, null::int) As Job
                   FROM Tmp_DataPackageItems
                   WHERE ItemType = 'Job' AND
                         Not DataPackageID Is Null) SourceQ
            WHERE Not Job Is Null
        End If;

        If Exists ( SELECT * FROM Tmp_DataPackageItems WHERE ItemType = 'Dataset' ) Then
            -- Auto-remove .raw and .d from the end of dataset names
            Update Tmp_DataPackageItems
            Set Identifier = Substring(Identifier, 1, char_length(Identifier) - 4)
            Where ItemType = 'Dataset' And Tmp_DataPackageItems.Identifier Like '%.raw'

            Update Tmp_DataPackageItems
            Set Identifier = Substring(Identifier, 1, char_length(Identifier) - 2)
            Where ItemType = 'Dataset' And Tmp_DataPackageItems.Identifier Like '%.d'

            -- Auto-convert dataset IDs to dataset names
            -- First look for dataset IDs
            INSERT INTO Tmp_DatasetIDsToAdd( DataPackageID, DatasetID )
            SELECT DataPackageID,
                   DatasetID
            FROM ( SELECT DataPackageID,
                          try_cast(Identifier, null::int) AS DatasetID
                   FROM Tmp_DataPackageItems
                   WHERE ItemType = 'Dataset' AND
                         NOT DataPackageID IS NULL ) SourceQ
            WHERE NOT DatasetID IS NULL

            If Exists (SELECT * FROM Tmp_DatasetIDsToAdd) Then
                -- Add the dataset names
                INSERT INTO Tmp_DataPackageItems( DataPackageID,
                                  ItemType,
                                  Identifier )
                SELECT Source.DataPackageID,
                       'Dataset' AS ItemType,
                       DL.Dataset
                FROM Tmp_DatasetIDsToAdd Source
                     INNER JOIN V_Dataset_List_Report_2 DL
                       ON Source.DatasetID = DL.ID

                -- Update the Type of the Dataset IDs so that they will be ignored
                UPDATE Tmp_DataPackageItems
                SET ItemType = 'DatasetID'
                FROM Tmp_DatasetIDsToAdd
                WHERE Tmp_DataPackageItems.Identifier = Tmp_DatasetIDsToAdd.DatasetID::text;

            End If;

            If Exists (SELECT * FROM Tmp_DataPackageItems WHERE ItemType = 'Dataset' And Identifier SIMILAR TO 'DataPackage[_][0-9][0-9]%') Then

                SELECT string_agg(Identifier, ', ' ORDER BY Identifier)
                INTO _datasetsRemoved
                FROM Tmp_DataPackageItems
                WHERE ItemType = 'Dataset' And Identifier SIMILAR TO 'DataPackage[_][0-9][0-9]%';

                DELETE FROM Tmp_DataPackageItems
                WHERE ItemType = 'Dataset' And Identifier SIMILAR TO 'DataPackage[_][0-9][0-9]%'

                _actionMsg := format('Data packages cannot include placeholder data package datasets; removed "%s"', _datasetsRemoved);
                _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
            End If;

        End If;

        -- Add parent items and associated items to list for items in the list
        -- This process cascades up the DMS hierarchy of tracking entities, but not down
        --
        If _mode = 'add' Then
            -- Add datasets to list that are parents of jobs in the list
            -- (and are not already in the list)
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT DISTINCT
                J.DataPackageID,
                'Dataset',
                TX.Dataset
            FROM
                Tmp_JobsToAddOrDelete J
                INNER JOIN V_Analysis_Job_List_Report_2 TX
                  ON J.Job = TX.Job
            WHERE
                NOT EXISTS (
                    SELECT *
                    FROM Tmp_DataPackageItems
                    WHERE Tmp_DataPackageItems.ItemType = 'Dataset' AND Tmp_DataPackageItems.Identifier = TX.Dataset AND Tmp_DataPackageItems.DataPackageID = J.DataPackageID
                ) AND
                NOT TX.Dataset SIMILAR TO 'DataPackage[_][0-9][0-9]%';

            -- Add experiments to list that are parents of datasets in the list
            -- (and are not already in the list)
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT DISTINCT
                TP.DataPackageID,
                'Experiment',
                TX.Experiment
            FROM
                Tmp_DataPackageItems TP
                INNER JOIN V_Dataset_List_Report_2 TX
                ON TP.Identifier = TX.Dataset
            WHERE
                TP.ItemType = 'Dataset'
                AND NOT EXISTS (
                    SELECT *
                    FROM Tmp_DataPackageItems
                    WHERE Tmp_DataPackageItems.ItemType = 'Experiment' AND Tmp_DataPackageItems.Identifier = TX.Experiment AND Tmp_DataPackageItems.DataPackageID = TP.DataPackageID
                );

            -- Add EUS Proposals to list that are parents of datasets in the list
            -- (and are not already in the list)
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT DISTINCT
                TP.DataPackageID,
                'EUSProposal',
                TX.Proposal
            FROM
                Tmp_DataPackageItems TP
                INNER JOIN V_Dataset_List_Report_2 TX
                ON TP.Identifier = TX.Dataset
            WHERE
                TP.ItemType = 'Dataset'
                AND NOT EXISTS (
                    SELECT *
                    FROM Tmp_DataPackageItems
                    WHERE Tmp_DataPackageItems.ItemType = 'EUSProposal' AND Tmp_DataPackageItems.Identifier = TX.Proposal AND Tmp_DataPackageItems.DataPackageID = TP.DataPackageID
                )

            -- Add biomaterial items to list that are associated with experiments in the list
            -- (and are not already in the list)
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT DISTINCT
                TP.DataPackageID,
                'Biomaterial',
                TX.Biomaterial_Name
            FROM
                Tmp_DataPackageItems TP
                INNER JOIN V_Experiment_Biomaterial TX
                ON TP.Identifier = TX.Experiment
            WHERE
                TP.ItemType = 'Experiment' AND
                TX.Biomaterial_Name NOT IN ('(none)')
                AND NOT EXISTS (
                    SELECT *
                    FROM Tmp_DataPackageItems
                    WHERE Tmp_DataPackageItems.ItemType = 'Biomaterial' AND
                          Tmp_DataPackageItems.Identifier = TX.Biomaterial_Name AND
                          Tmp_DataPackageItems.DataPackageID = TP.DataPackageID
                );

        End If;

        If _mode = 'delete' And _removeParents > 0 Then
            -- Find Datasets, Experiments, Biomaterial, and Cell Culture items that we can safely delete
            -- after deleting the jobs and/or datasets in Tmp_DataPackageItems

            -- Find parent datasets that will have no jobs remaining once we remove the jobs in Tmp_DataPackageItems
            --
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT ToDelete.DataPackageID, ToDelete.ItemType, ToDelete.Dataset
            FROM (
                   -- Datasets associated with jobs that we are removing
                   SELECT DISTINCT J.DataPackageID,
                                   'Dataset' AS ItemType,
                                   TX.Dataset AS Dataset
                   FROM Tmp_JobsToAddOrDelete J
                       INNER JOIN V_Analysis_Job_List_Report_2 TX
                          ON J.Job = TX.Job
                 ) ToDelete
                 LEFT OUTER JOIN (
                        -- Datasets associated with the data package; skipping the jobs that we're deleting
                        SELECT Datasets.dataset,
                               Datasets.data_pkg_id
                        FROM dpkg.t_data_package_analysis_jobs Jobs
                             INNER JOIN dpkg.t_data_package_datasets Datasets
                               ON Jobs.data_pkg_id = Datasets.data_pkg_id AND
                                  Jobs.dataset_id = Datasets.dataset_id
                             LEFT OUTER JOIN Tmp_JobsToAddOrDelete ItemsQ
                               ON Jobs.data_pkg_id = ItemsQ.DataPackageID AND
                                  Jobs.job = ItemsQ.job
                        WHERE Jobs.data_pkg_id IN (SELECT DISTINCT DataPackageID FROM Tmp_JobsToAddOrDelete) AND
                              ItemsQ.job IS NULL
                 ) AS ToKeep
                   ON ToDelete.DataPackageID = ToKeep.data_pkg_id AND
                      ToDelete.dataset = ToKeep.dataset
            WHERE ToKeep.data_pkg_id IS NULL

            -- Find parent experiments that will have no jobs or datasets remaining once we remove the jobs in Tmp_DataPackageItems
            --
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT ToDelete.DataPackageID, ToDelete.ItemType, ToDelete.Experiment
            FROM (
                   -- Experiments associated with jobs or datasets that we are removing
                   SELECT DISTINCT J.DataPackageID,
                                   'Experiment' AS ItemType,
                                   TX.Experiment AS Experiment
                   FROM Tmp_JobsToAddOrDelete J
                        INNER JOIN V_Analysis_Job_List_Report_2 TX
                          ON J.Job = TX.Job
                   UNION
                   SELECT DISTINCT TP.DataPackageID,
                                   'Experiment',
                                   TX.Experiment
                   FROM Tmp_DataPackageItems TP
                        INNER JOIN V_Dataset_List_Report_2 TX
                          ON TP.Identifier = TX.Dataset
                   WHERE TP.ItemType = 'Dataset'
                 ) ToDelete
                 LEFT OUTER JOIN (
                        -- Experiments associated with the data package; skipping any jobs that we're deleting
                        SELECT Experiments.experiment,
                               Datasets.data_pkg_id
                        FROM dpkg.t_data_package_analysis_jobs Jobs
                             INNER JOIN dpkg.t_data_package_datasets Datasets
                               ON Jobs.data_pkg_id = Datasets.data_pkg_id AND
                                  Jobs.dataset_id = Datasets.dataset_id
                             INNER JOIN dpkg.t_data_package_experiments Experiments
                               ON Datasets.experiment = Experiments.experiment AND
                                  Datasets.data_pkg_id = Experiments.data_pkg_id
                             LEFT OUTER JOIN Tmp_JobsToAddOrDelete ItemsQ
                               ON Jobs.data_pkg_id = ItemsQ.DataPackageID AND
                                   Jobs.job = ItemsQ.job
                        WHERE Jobs.data_pkg_id IN (SELECT DISTINCT DataPackageID FROM Tmp_JobsToAddOrDelete) AND
                              ItemsQ.job IS NULL
                 ) AS ToKeep1
                   ON ToDelete.DataPackageID = ToKeep1.data_pkg_id AND
                      ToDelete.experiment = ToKeep1.experiment
                 LEFT OUTER JOIN (
                        -- Experiments associated with the data package; skipping any datasets that we're deleting
                        SELECT Experiments.experiment,
                               Datasets.data_pkg_id
                        FROM dpkg.t_data_package_datasets Datasets
                             INNER JOIN dpkg.t_data_package_experiments Experiments
                               ON Datasets.experiment = Experiments.experiment AND
                                  Datasets.data_pkg_id = Experiments.data_pkg_id
                             LEFT OUTER JOIN Tmp_DataPackageItems ItemsQ
                               ON Datasets.data_pkg_id = ItemsQ.DataPackageID AND
                                   ItemsQ.type = 'dataset' AND
                                   ItemsQ.Identifier = Datasets.dataset
                        WHERE Datasets.data_pkg_id IN (SELECT DISTINCT DataPackageID FROM Tmp_DataPackageItems) AND
                              ItemsQ.Identifier IS NULL
                 ) AS ToKeep2
                   ON ToDelete.DataPackageID = ToKeep2.data_pkg_id AND
                      ToDelete.experiment = ToKeep2.experiment
            WHERE ToKeep1.data_pkg_id IS NULL AND
                  ToKeep2.data_pkg_id IS NULL

            -- Find parent biomaterial that will have no jobs or datasets remaining once we remove the jobs in Tmp_DataPackageItems
            --
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT ToDelete.DataPackageID, ToDelete.ItemType, ToDelete.Biomaterial_Name
            FROM (
                   -- Biomaterial associated with jobs that we are removing
                   SELECT DISTINCT J.DataPackageID,
                                   'Biomaterial' AS ItemType,
                                   Biomaterial.Biomaterial_Name
                   FROM Tmp_JobsToAddOrDelete J
                        INNER JOIN V_Analysis_Job_List_Report_2 TX
                          ON J.Job = TX.Job
                        INNER JOIN V_Experiment_Biomaterial Biomaterial
                          ON Biomaterial.Experiment = TX.Experiment
                 ) ToDelete
                 LEFT OUTER JOIN (
                        -- Biomaterial associated with the data package; skipping the jobs that we're deleting
                        SELECT DISTINCT biomaterial.biomaterial AS biomaterial_name,
                                        Datasets.data_pkg_id
                        FROM dpkg.t_data_package_analysis_jobs Jobs
                             INNER JOIN dpkg.t_data_package_datasets Datasets
                               ON Jobs.data_pkg_id = Datasets.data_pkg_id AND
                                  Jobs.dataset_id = Datasets.dataset_id
                             INNER JOIN dpkg.t_data_package_experiments Experiments
                               ON Datasets.experiment = Experiments.experiment AND
                                  Datasets.data_pkg_id = Experiments.data_pkg_id
                             INNER JOIN dpkg.t_data_package_biomaterial biomaterial
                               ON Experiments.data_pkg_id = biomaterial.data_pkg_id
                             INNER JOIN V_Experiment_Biomaterial Exp_Biomaterial_Map
                               ON Experiments.experiment = Exp_Biomaterial_Map.Experiment AND
                                  Exp_Biomaterial_Map.biomaterial_name = biomaterial.biomaterial
                             LEFT OUTER JOIN Tmp_JobsToAddOrDelete ItemsQ
                               ON Jobs.data_pkg_id = ItemsQ.DataPackageID AND
                                  Jobs.job = ItemsQ.job
                        WHERE Jobs.data_pkg_id IN (SELECT DISTINCT DataPackageID FROM Tmp_JobsToAddOrDelete) AND
                              ItemsQ.job IS NULL
                 ) AS ToKeep
                   ON ToDelete.DataPackageID = ToKeep.data_pkg_id AND
                      ToDelete.biomaterial_name = ToKeep.biomaterial_name
            WHERE ToKeep.data_pkg_id IS NULL

        End If;

        ---------------------------------------------------
        -- Possibly preview the items
        ---------------------------------------------------

        If _infoOnly Then
            If Not _mode::citext In ('add', 'comment', 'delete') Then
                RAISE WARNING '_mode should be add, comment, or delete; % is invalid', _mode;
            End If;

            RAISE INFO '';

            _formatSpecifier := '%-11s %-12s %-80s';

            _infoHead := format(_formatSpecifier,
                                'Data_Pkg_ID',
                                'Item_Type',
                                'Identifier'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '-----------',
                                         '------------',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT DataPackageID,
                       ItemType,
                       Identifier
                FROM Tmp_DataPackageItems
                ORDER BY DataPackageID, ItemType, Identifier
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.DataPackageID,
                                    _previewData.ItemType,
                                    _previewData.Identifier
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_DatasetIDsToAdd;
            DROP TABLE Tmp_JobsToAddOrDelete;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Biomaterial operations
        ---------------------------------------------------

        If _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Biomaterial') Then
            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-22s %-11s %-15s %-10s %-80s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'Data_Pkg_ID',
                                    'Biomaterial_ID',
                                    'Type',
                                    'Biomaterial'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '----------------------',
                                             '-----------',
                                             '---------------',
                                             '----------',
                                             '--------------------------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT 'Delete Biomaterial' AS Action,
                           Target.Data_Pkg_ID,
                           Target.Biomaterial_ID,
                           Target.Type,
                           Target.Biomaterial
                    FROM dpkg.t_data_package_biomaterial Target
                         INNER JOIN Tmp_DataPackageItems
                           ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                              Tmp_DataPackageItems.Identifier = Target.biomaterial AND
                              Tmp_DataPackageItems.ItemType = 'Biomaterial'
                    ORDER BY Target.Data_Pkg_ID, Target.Biomaterial_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Biomaterial_ID,
                                        _previewData.Type,
                                        _previewData.Biomaterial
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                DELETE Target
                FROM dpkg.t_data_package_biomaterial Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.biomaterial AND
                          Tmp_DataPackageItems.ItemType = 'Biomaterial';
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _deleteCount;
                    _actionMsg := format('Deleted %s biomaterial %s', _deleteCount, public.check_plural(_deleteCount, 'item', 'items'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Biomaterial') Then
            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-22s %-60s %-11s %-15s %-10s %-80s %-60s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'New_Comment',
                                    'Data_Pkg_ID',
                                    'Biomaterial_ID',
                                    'Type',
                                    'Biomaterial',
                                    'Old_Comment'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '----------------------',
                                             '------------------------------------------------------------',
                                             '-----------',
                                             '---------------',
                                             '----------',
                                             '--------------------------------------------------------------------------------',
                                             '------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT 'Update Biomaterial Comment' AS Action,
                           _comment AS New_Comment,
                           Target.Data_Pkg_ID,
                           Target.Biomaterial_ID,
                           Target.Type,
                           Target.Biomaterial,
                           Target.package_comment AS Old_Comment
                    FROM dpkg.t_data_package_biomaterial Target
                         INNER JOIN Tmp_DataPackageItems
                           ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                              Tmp_DataPackageItems.Identifier = Target.biomaterial AND
                              Tmp_DataPackageItems.ItemType = 'Biomaterial'
                    ORDER BY Target.Data_Pkg_ID, Target.Biomaterial_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.New_Comment,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Biomaterial_ID,
                                        _previewData.Type,
                                        _previewData.Biomaterial,
                                        _previewData.Old_Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                UPDATE dpkg.t_data_package_biomaterial
                SET package_comment = _comment
                FROM Tmp_DataPackageItems Src
                WHERE Src.DataPackageID = dpkg.t_data_package_biomaterial.Data_Package_ID AND
                      Src.Identifier = dpkg.t_data_package_biomaterial.Name AND
                      Src.ItemType = 'Biomaterial';
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                If _updateCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _updateCount;
                    _actionMsg := format('Updated the comment for %s biomaterial %s', _updateCount, public.check_plural(_updateCount, 'item', 'items'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Biomaterial') Then
            -- Delete extras
            DELETE FROM Tmp_DataPackageItems target
            WHERE EXISTS
                ( SELECT 1
                  FROM Tmp_DataPackageItems PkgItems
                       INNER JOIN dpkg.t_data_package_biomaterial TX
                         ON PkgItems.DataPackageID = TX.data_pkg_id AND
                            PkgItems.Identifier = TX.biomaterial AND
                            PkgItems.ItemType = 'biomaterial'
                  WHERE target.DataPackageID = PkgItems.DataPackageID AND
                        target.Identifier = PkgItems.Identifier AND
                        target.ItemType = PkgItems.type
                );

            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-28s %-11s %-15s %-10s %-80s %-60s %-60s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'Data_Pkg_ID',
                                    'Biomaterial_ID',
                                    'Type',
                                    'Biomaterial',
                                    'Campaign',
                                    'Comment'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '----------------------------',
                                             '-----------',
                                             '---------------',
                                             '----------',
                                             '--------------------------------------------------------------------------------',
                                             '------------------------------------------------------------',
                                             '------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT DISTINCT 'Add Biomaterial to Data Pkg' As Action,
                                    Tmp_DataPackageItems.DataPackageID As Data_Pkg_ID,
                                    TX.ID As Biomaterial_ID,
                                    TX.Type,
                                    TX.Name As Biomaterial,
                                    TX.Campaign,
                                    _comment AS Comment
                    FROM Tmp_DataPackageItems
                         INNER JOIN V_Biomaterial_List_Report_2 TX
                           ON Tmp_DataPackageItems.Identifier = TX.Name
                    WHERE Tmp_DataPackageItems.ItemType = 'Biomaterial'
                    ORDER BY Tmp_DataPackageItems.DataPackageID, TX.ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Biomaterial_ID,
                                        _previewData.Type,
                                        _previewData.Biomaterial,
                                        _previewData.Campaign,
                                        _previewData.Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                -- Add new items
                INSERT INTO dpkg.t_data_package_biomaterial(
                    data_pkg_id,
                    biomaterial_id,
                    package_comment,
                    biomaterial,
                    campaign,
                    created,
                    type
                )
                SELECT DISTINCT
                    Tmp_DataPackageItems.DataPackageID,
                    TX.ID,
                    _comment,
                    TX.name,
                    TX.campaign,
                    TX.created,
                    TX.type
                FROM Tmp_DataPackageItems
                     INNER JOIN V_Biomaterial_List_Report_2 TX
                       ON Tmp_DataPackageItems.Identifier = TX.name
                WHERE Tmp_DataPackageItems.ItemType = 'Biomaterial';
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _insertCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _insertCount;
                    _actionMsg := format('Added %s biomaterial %s', _insertCount, public.check_plural(_insertCount, 'item', 'items'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- EUS Proposal operations
        ---------------------------------------------------

        If _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'EUSProposal') Then
            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-20s %-11s %-11s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'Data_Pkg_ID',
                                    'Proposal_ID'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '--------------------',
                                             '-----------',
                                             '-----------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT 'Delete EUS Proposal' AS Action,
                           Target.Data_Pkg_ID,
                           Target.Proposal_ID
                    FROM dpkg.t_data_package_eus_proposals Target
                         INNER JOIN Tmp_DataPackageItems
                           ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                              Tmp_DataPackageItems.Identifier = Target.proposal_id AND
                              Tmp_DataPackageItems.ItemType = 'EUSProposal'
                    ORDER BY Target.Data_Pkg_ID, Target.Proposal_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Proposal_ID
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                DELETE Target
                FROM dpkg.t_data_package_eus_proposals Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.proposal_id AND
                          Tmp_DataPackageItems.ItemType = 'EUSProposal'
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _deleteCount;
                    _actionMsg := format('Deleted %s EUS %s', _deleteCount, public.check_plural(_deleteCount, 'proposal', 'proposals'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'EUSProposal') Then
            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-28s %-60s %-11s %-11s %-60s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'New_Comment',
                                    'Data_Pkg_ID',
                                    'Proposal_ID',
                                    'Old_Comment'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '----------------------------',
                                             '------------------------------------------------------------',
                                             '-----------',
                                             '-----------',
                                             '------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT 'Update EUS Proposal Comment' AS Action,
                           _comment AS New_Comment,
                           Target.Data_Pkg_ID,
                           Target.Proposal_ID,
                           Target.package_comment AS Old_Comment
                    FROM t_data_package_eus_proposals Target
                         INNER JOIN Tmp_DataPackageItems
                           ON Tmp_DataPackageItems.DataPackageID = Target.Data_Package_ID AND
                              Tmp_DataPackageItems.Identifier = Target.Proposal_ID AND
                              Tmp_DataPackageItems.ItemType = 'EUSProposal'
                    ORDER BY Target.Data_Pkg_ID, Target.Proposal_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.New_Comment,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Proposal_ID,
                                        _previewData.Old_Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                UPDATE dpkg.t_data_package_eus_proposals
                SET package_comment = _comment
                FROM Tmp_DataPackageItems
                WHERE Tmp_DataPackageItems.DataPackageID = dpkg.t_data_package_eus_proposals.Data_Package_ID AND
                      Tmp_DataPackageItems.Identifier = dpkg.t_data_package_eus_proposals.Proposal_ID AND
                      Tmp_DataPackageItems.ItemType = 'EUSProposal';
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                If _updateCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _updateCount;
                    _actionMsg := format('Updated the comment for %s EUS %s', _updateCount, public.check_plural(_updateCount, 'proposal', 'proposals'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'EUSProposal') Then
            -- Delete extras
            DELETE FROM Tmp_DataPackageItems target
            WHERE EXISTS
                ( SELECT 1
                  FROM Tmp_DataPackageItems PkgItems
                       INNER JOIN dpkg.t_data_package_eus_proposals TX
                         ON PkgItems.DataPackageID = TX.data_pkg_id AND
                            PkgItems.Identifier = TX.proposal_id AND
                            PkgItems.ItemType = 'EUSProposal'
                  WHERE target.DataPackageID = PkgItems.DataPackageID AND
                        target.Identifier = PkgItems.Identifier AND
                        target.ItemType = PkgItems.type
                );

            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-30s %-11s %-11s %-90s %-60s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'Data_Pkg_ID',
                                    'Proposal_ID',
                                    'Proposal',
                                    'Comment'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '------------------------------',
                                             '-----------',
                                             '-----------',
                                             '------------------------------------------------------------------------------------------',
                                             '------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT DISTINCT 'Add EUS Proposal to Data Pkg' As Action,
                                    Tmp_DataPackageItems.DataPackageID As Data_Pkg_ID,
                                    TX.ID As Proposal_ID,
                                    Substring(TX.Title, 1, 90) As Proposal,
                                    _comment As Comment
                    FROM Tmp_DataPackageItems
                         INNER JOIN V_EUS_Proposals_List_Report TX
                           ON Tmp_DataPackageItems.Identifier = TX.ID
                    WHERE Tmp_DataPackageItems.ItemType = 'EUSProposal'
                    ORDER BY Tmp_DataPackageItems.DataPackageID, TX.ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Proposal_ID,
                                        _previewData.Proposal,
                                        _previewData.Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                -- Add new items
                INSERT INTO dpkg.t_data_package_eus_proposals( data_pkg_id,
                                                               proposal_id,
                                                               package_comment )
                SELECT DISTINCT Tmp_DataPackageItems.DataPackageID,
                                TX.ID,
                                _comment
                FROM Tmp_DataPackageItems
                     INNER JOIN V_EUS_Proposals_List_Report TX
                       ON Tmp_DataPackageItems.Identifier = TX.ID
                WHERE Tmp_DataPackageItems.ItemType = 'EUSProposal'

                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _insertCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _insertCount;
                    _actionMsg := format('Added %s EUS %s', _insertCount, public.check_plural(_insertCount, 'proposal', 'proposals'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- Experiment operations
        ---------------------------------------------------

        If _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Experiment') Then
            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-18s %-11s %-13s %-80s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'Data_Pkg_ID',
                                    'Experiment_ID',
                                    'Experiment'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '------------------',
                                             '-----------',
                                             '-------------',
                                             '--------------------------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT 'Delete Experiment' AS Action,
                           Target.Data_Pkg_ID,
                           Target.Experiment_ID,
                           Target.Experiment
                    FROM dpkg.t_data_package_experiments Target
                         INNER JOIN Tmp_DataPackageItems
                           ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                              Tmp_DataPackageItems.Identifier = Target.experiment AND
                              Tmp_DataPackageItems.ItemType = 'Experiment'
                    ORDER BY Target.Data_Pkg_ID, Target.Experiment_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Experiment_ID,
                                        _previewData.Experiment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                DELETE Target
                FROM dpkg.t_data_package_experiments Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                  Tmp_DataPackageItems.Identifier = Target.experiment AND
                          Tmp_DataPackageItems.ItemType = 'Experiment'
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _deleteCount;
                    _actionMsg := format('Deleted %s %s', _deleteCount, public.check_plural(_deleteCount, 'experiment', 'experiments');
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Experiment') Then
            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-25s %-60s %-11s %-13s %-60s %-60s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'New_Comment',
                                    'Data_Pkg_ID',
                                    'Experiment_ID',
                                    'Experiment',
                                    'Old_Comment'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '-------------------------',
                                             '------------------------------------------------------------',
                                             '-----------',
                                             '-------------',
                                             '------------------------------------------------------------',
                                             '------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT 'Update Experiment Comment' AS Action,
                           _comment AS New_Comment,
                           Target.Data_Pkg_ID,
                           Target.Experiment_ID,
                           Target.Experiment,
                           Target.package_comment AS Old_Comment
                    FROM dpkg.t_data_package_experiments Target
                         INNER JOIN Tmp_DataPackageItems
                           ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                              Tmp_DataPackageItems.Identifier = Target.experiment AND
                              Tmp_DataPackageItems.ItemType = 'Experiment'
                    ORDER BY Target.Data_Pkg_ID, Target.Experiment_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.New_Comment,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Experiment_ID,
                                        _previewData.Experiment,
                                        _previewData.Old_Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                UPDATE dpkg.t_data_package_experiments
                SET package_comment = _comment
                FROM Tmp_DataPackageItems
                WHERE Tmp_DataPackageItems.DataPackageID = dpkg.t_data_package_experiments.Data_Package_ID AND
                      Tmp_DataPackageItems.Identifier = dpkg.t_data_package_experiments.Experiment AND
                      Tmp_DataPackageItems.ItemType = 'Experiment'
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                If _updateCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _updateCount;
                    _actionMsg := format('Updated the comment for %s %s', _updateCount, public.check_plural(_updateCount, 'experiment', 'experiments'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Experiment') Then
            -- Delete extras
            DELETE FROM Tmp_DataPackageItems target
            WHERE EXISTS
                ( SELECT 1
                  FROM Tmp_DataPackageItems PkgItems
                       INNER JOIN dpkg.t_data_package_experiments TX
                         ON PkgItems.DataPackageID = TX.data_pkg_id AND
                            PkgItems.Identifier = TX.experiment AND
                            PkgItems.ItemType = 'experiment'
                  WHERE target.DataPackageID = PkgItems.DataPackageID AND
                        target.Identifier = PkgItems.Identifier AND
                        target.ItemType = PkgItems.type
                );

            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-28s %-11s %-13s %-60s %-60s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'Data_Pkg_ID',
                                    'Experiment_ID',
                                    'Experiment',
                                    'Comment'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '----------------------------',
                                             '-----------',
                                             '-------------',
                                             '------------------------------------------------------------',
                                             '------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT DISTINCT 'Add Experiment to Data Pkg' As Action,
                                    Tmp_DataPackageItems.DataPackageID As Data_Pkg_ID,
                                    TX.ID As Experiment_ID,
                                    TX.Experiment,
                                    _comment As Comment
                    FROM Tmp_DataPackageItems
                         INNER JOIN V_Experiment_List_Report TX
                           ON Tmp_DataPackageItems.Identifier = TX.Experiment
                    WHERE Tmp_DataPackageItems.ItemType = 'Experiment'
                    ORDER BY Tmp_DataPackageItems.DataPackageID, TX.ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Experiment_ID,
                                        _previewData.Experiment,
                                        _previewData.Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                -- Add new items
                INSERT INTO dpkg.t_data_package_experiments(
                    data_pkg_id,
                    experiment_id,
                    package_comment,
                    experiment,
                    created
                )
                SELECT DISTINCT
                    Tmp_DataPackageItems.DataPackageID,
                    TX.ID,
                    _comment,
                    TX.experiment,
                    TX.created
                FROM Tmp_DataPackageItems
                     INNER JOIN V_Experiment_List_Report TX
                       ON Tmp_DataPackageItems.Identifier = TX.experiment
                WHERE Tmp_DataPackageItems.ItemType = 'Experiment'
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _insertCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _insertCount;
                    _actionMsg := format('Added %s %s', _insertCount, public.check_plural(_insertCount, 'experiment', 'experiments'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- Dataset operations
        ---------------------------------------------------

        If _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Dataset') Then
            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-15s %-11s %-10s %-80s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'Data_Pkg_ID',
                                    'Dataset_ID',
                                    'Dataset'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '---------------',
                                             '-----------',
                                             '----------',
                                             '--------------------------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT 'Delete Dataset' AS Action,
                           Target.Data_Pkg_ID,
                           Target.Dataset_ID,
                           Target.Dataset
                    FROM dpkg.t_data_package_datasets Target
                         INNER JOIN Tmp_DataPackageItems
                           ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                              Tmp_DataPackageItems.Identifier = Target.dataset AND
                              Tmp_DataPackageItems.ItemType = 'Dataset'
                    ORDER BY Target.Data_Pkg_ID, Target.Dataset_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Dataset_ID,
                                        _previewData.Dataset
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                DELETE Target
                FROM dpkg.t_data_package_datasets Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.dataset AND
                          Tmp_DataPackageItems.ItemType = 'Dataset'
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _deleteCount;
                    _actionMsg := format('Deleted %s %s', _deleteCount, public.check_plural(_deleteCount, 'dataset', 'datasets'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Dataset') Then
            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-22s %-60s %-11s %-10s %-80s %-60s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'New_Comment',
                                    'Data_Pkg_ID',
                                    'Dataset_ID',
                                    'Dataset',
                                    'Old_Comment'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '----------------------',
                                             '------------------------------------------------------------',
                                             '-----------',
                                             '----------',
                                             '--------------------------------------------------------------------------------',
                                             '------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT 'Update Dataset Comment' AS Action,
                           _comment AS New_Comment,
                           Target.Data_Pkg_ID,
                           Target.Dataset_ID,
                           Target.Dataset,
                           Target.package_comment AS Old_Comment
                    FROM dpkg.t_data_package_datasets Target
                         INNER JOIN Tmp_DataPackageItems
                           ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                              Tmp_DataPackageItems.Identifier = Target.dataset AND
                              Tmp_DataPackageItems.ItemType = 'Dataset'
                    ORDER BY Target.Data_Pkg_ID, Target.Dataset_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.New_Comment,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Dataset_ID,
                                        _previewData.Dataset,
                                        _previewData.Old_Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                UPDATE dpkg.t_data_package_datasets
                SET package_comment = _comment
                FROM Tmp_DataPackageItems
                WHERE Tmp_DataPackageItems.DataPackageID = dpkg.t_data_package_datasets.Data_Package_ID AND
                      Tmp_DataPackageItems.Identifier = dpkg.t_data_package_datasets.Dataset AND
                      Tmp_DataPackageItems.ItemType = 'Dataset'
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                If _updateCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _updateCount;
                    _actionMsg := format('Updated the comment for %s %s', _updateCount, public.check_plural(_updateCount, 'dataset', 'datasets'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Dataset') Then
            -- Delete extras
            DELETE FROM Tmp_DataPackageItems target
            WHERE EXISTS
                ( SELECT 1
                  FROM Tmp_DataPackageItems PkgItems
                       INNER JOIN dpkg.t_data_package_datasets TX
                         ON PkgItems.DataPackageID = TX.data_pkg_id AND
                            PkgItems.Identifier = TX.dataset AND
                            PkgItems.ItemType = 'dataset'
                  WHERE target.DataPackageID = PkgItems.DataPackageID AND
                        target.Identifier = PkgItems.Identifier AND
                        target.ItemType = PkgItems.type
                );

            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-25s %-11s %-10s %-80s %-20s %-60s %-30s %-60s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'Data_Pkg_ID',
                                    'Dataset_ID',
                                    'Dataset',
                                    'Created',
                                    'Experiment',
                                    'Instrument',
                                    'Comment'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '-------------------------',
                                             '-----------',
                                             '----------',
                                             '--------------------------------------------------------------------------------',
                                             '--------------------',
                                             '------------------------------------------------------------',
                                             '------------------------------',
                                             '------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT DISTINCT 'Add Dataset to Data Pkg' AS Action,
                                    Tmp_DataPackageItems.DataPackageID AS Data_Pkg_ID,
                                    TX.ID AS Dataset_ID,
                                    TX.Dataset,
                                    public.timestamp_text(TX.Created) As Created,
                                    TX.Experiment,
                                    TX.Instrument,
                                    _comment AS Comment
                    FROM Tmp_DataPackageItems
                         INNER JOIN V_Dataset_List_Report_2 TX
                           ON Tmp_DataPackageItems.Identifier = TX.Dataset
                    WHERE Tmp_DataPackageItems.ItemType = 'Dataset'
                    ORDER BY Tmp_DataPackageItems.DataPackageID, TX.ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Dataset_ID,
                                        _previewData.Dataset,
                                        _previewData.Created,
                                        _previewData.Experiment,
                                        _previewData.Instrument
                                        _previewData.Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                -- Add new items
                INSERT INTO dpkg.t_data_package_datasets( data_pkg_id,
                                                          dataset_id,
                                                          package_comment,
                                                          dataset,
                                                          created,
                                                          experiment,
                                                          instrument )
                SELECT DISTINCT Tmp_DataPackageItems.DataPackageID,
                                TX.ID,
                                _comment,
                                TX.dataset,
                                TX.created,
                                TX.experiment,
                                TX.instrument
                FROM Tmp_DataPackageItems
                     INNER JOIN V_Dataset_List_Report_2 TX
                       ON Tmp_DataPackageItems.Identifier = TX.dataset
                WHERE Tmp_DataPackageItems.ItemType = 'Dataset'
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _insertCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _insertCount;
                    _actionMsg := format('Added %s %s', _insertCount, public.check_plural(_insertCount, 'dataset', 'datasets'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- Analysis_job operations
        ---------------------------------------------------

        If _mode = 'delete' And Exists (Select * From Tmp_JobsToAddOrDelete) Then
            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-20s %-11s %-10s %-35s %-10s %-80s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'Data_Pkg_ID',
                                    'Job',
                                    'Tool',
                                    'Dataset_ID',
                                    'Dataset'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '--------------------',
                                             '-----------',
                                             '----------',
                                             '-----------------------------------',
                                             '----------',
                                             '--------------------------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT 'Delete Analysis Job' AS Action,
                           Target.Data_Pkg_ID,
                           Target.Job,
                           Target.Tool,
                           Target.Dataset_ID,
                           Target.Dataset
                    FROM dpkg.t_data_package_analysis_jobs Target
                         INNER JOIN Tmp_JobsToAddOrDelete ItemsQ
                           ON Target.data_pkg_id = ItemsQ.DataPackageID AND
                              Target.job = ItemsQ.job
                    ORDER BY Target.Data_Pkg_ID, Target.Job
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Job,
                                        _previewData.Tool,
                                        _previewData.Dataset_ID,
                                        _previewData.Dataset
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                DELETE Target
                FROM dpkg.t_data_package_analysis_jobs Target
                     INNER JOIN Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.data_pkg_id = ItemsQ.DataPackageID AND
                          Target.job = ItemsQ.job
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _deleteCount;
                    _actionMsg := format('Deleted %s analysis %s', _deleteCount, public.check_plural(_deleteCount, 'job', 'jobs'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'comment' And Exists (Select * From Tmp_JobsToAddOrDelete) Then
            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-22s %-60s %-11s %-10s %-35s %-10s %-60s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'New_Comment',
                                    'Data_Pkg_ID',
                                    'Job',
                                    'Tool',
                                    'Dataset_ID',
                                    'Old_Comment'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                         '----------------------',
                                         '------------------------------------------------------------',
                                         '-----------',
                                         '----------',
                                         '-----------------------------------',
                                         '----------',
                                         '------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT 'Update Job Comment' AS Action,
                           _comment AS New_Comment,
                           Target.Data_Pkg_ID,
                           Target.Job,
                           Target.Tool,
                           Target.Dataset_ID,
                           Target.package_comment AS Old_Comment
                    FROM dpkg.t_data_package_analysis_jobs Target
                         INNER JOIN Tmp_JobsToAddOrDelete ItemsQ
                           ON Target.data_pkg_id = ItemsQ.DataPackageID AND
                              Target.job = ItemsQ.job
                    ORDER BY Target.Data_Pkg_ID, Target.Job
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.New_Comment,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Job,
                                        _previewData.Tool,
                                        _previewData.Dataset_ID,
                                        _previewData.Old_Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                UPDATE Target
                SET package_comment = _comment
                FROM dpkg.t_data_package_analysis_jobs Target
                     INNER JOIN Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.data_pkg_id = ItemsQ.DataPackageID AND
                          Target.job = ItemsQ.job
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                If _updateCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _updateCount;
                    _actionMsg := format('Updated the comment for %s analysis %s', _updateCount, public.check_plural(_updateCount, 'job', 'jobs'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'add' And Exists (Select * From Tmp_JobsToAddOrDelete) Then
            -- Delete extras
            DELETE FROM Tmp_JobsToAddOrDelete Target
            WHERE EXISTS
                ( SELECT 1
                  FROM Tmp_JobsToAddOrDelete PkgJobs
                       INNER JOIN dpkg.t_data_package_analysis_jobs TX
                         ON PkgJobs.DataPackageID = TX.data_pkg_id AND
                            PkgJobs.job = TX.job
                  WHERE Target.DataPackageID = PkgJobs.DataPackageID AND
                        Target.job = PkgJobs.job
                );

            If _infoOnly Then

                RAISE INFO '';

                _formatSpecifier := '%-20s %-11s %-10s %-35s %-20s %-80s %-60s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'Data_Pkg_ID',
                                    'Job',
                                    'Tool',
                                    'Created',
                                    'Dataset',
                                    'Comment'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '--------------------',
                                             '-----------',
                                             '----------',
                                             '-----------------------------------',
                                             '--------------------',
                                             '--------------------------------------------------------------------------------',
                                             '------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT DISTINCT 'Add Job to Data Pkg' AS Action,
                                    ItemsQ.DataPackageID AS Data_Pkg_ID,
                                    TX.Job,
                                    TX.Tool
                                    public.timestamp_text(TX.Created) As Created,
                                    TX.Dataset,
                                    _comment AS Comment
                    FROM V_Analysis_Job_List_Report_2 TX
                         INNER JOIN Tmp_JobsToAddOrDelete ItemsQ
                           ON TX.Job = ItemsQ.Job
                    ORDER BY ItemsQ.DataPackageID, TX.Job
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Job,
                                        _previewData.Tool,
                                        _previewData.Created,
                                        _previewData.Dataset,
                                        _previewData.Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                -- Add new items
                INSERT INTO dpkg.t_data_package_analysis_jobs( data_pkg_id,
                                                               job,
                                                               package_comment,
                                                               created,
                                                               dataset_id,
                                                               dataset,
                                                               tool )
                SELECT DISTINCT ItemsQ.DataPackageID,
                                TX.job,
                                _comment,
                                TX.created,
                                TX.dataset_id,
                                TX.dataset,
                                TX.tool
                FROM V_Analysis_Job_List_Report_2 TX
                     INNER JOIN Tmp_JobsToAddOrDelete ItemsQ
                       ON TX.job = ItemsQ.job
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _insertCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _insertCount;
                    _actionMsg := format('Added %s analysis %s', _insertCount, public.check_plural(_insertCount, 'job', 'jobs'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- Update item counts for all data packages in the list
        ---------------------------------------------------

        If _itemCountChanged > 0 Then

            CREATE TEMP TABLE Tmp_DataPackageDatasets (ID int)

            _createdDataPackageDatasetsTable := true;

            INSERT INTO Tmp_DataPackageDatasets (ID)
            SELECT DISTINCT DataPackageID
            FROM Tmp_DataPackageItems

            FOR _packageID IN
                SELECT ID
                FROM Tmp_DataPackageDatasets
                ORDER BY ID
            LOOP
                CALL update_data_package_item_counts (_packageID);
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Update EUS Info for all data packages in the list
        ---------------------------------------------------

        If _itemCountChanged > 0 Then

            SELECT string_agg(DataPackageID::text, ',' ORDER BY DataPackageID)
            INTO _dataPackageList
            FROM ( SELECT DISTINCT DataPackageID
                   FROM Tmp_DataPackageItems ) AS ListQ;

            CALL update_data_package_eus_info (_dataPackageList);
        End If;

        ---------------------------------------------------
        -- Update the last modified date for affected data packages
        ---------------------------------------------------

        If _itemCountChanged > 0 Then
            UPDATE dpkg.t_data_package
            SET last_modified = CURRENT_TIMESTAMP
            WHERE data_pkg_id IN (
                SELECT DISTINCT DataPackageID FROM Tmp_DataPackageItems
            )
        End If;

        If _message = '' Then
            _message := 'No items were updated';

            If _mode = 'add' Then
                _message := 'No items were added';
            End If;

            If _mode = 'delete' Then
                _message := 'No items were removed';
            End If;
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

    DROP TABLE Tmp_DatasetIDsToAdd;
    DROP TABLE Tmp_JobsToAddOrDelete;

    If _createdDataPackageDatasetsTable Then
        DROP TABLE Tmp_DataPackageDatasets;
    End If;
END
$$;

COMMENT ON PROCEDURE dpkg.update_data_package_items_utility IS 'UpdateDataPackageItemsUtility';
