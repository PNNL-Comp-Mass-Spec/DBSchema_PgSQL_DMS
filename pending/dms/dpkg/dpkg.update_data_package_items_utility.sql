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
**          06/10/2009 grk - changed size of item list to max
**          06/10/2009 mem - Now calling UpdateDataPackageItemCounts to update the data package item counts
**          10/01/2009 mem - Now populating Campaign in T_Data_Package_Biomaterial
**          12/31/2009 mem - Added DISTINCT keyword to the INSERT INTO queries in case the source views include some duplicate rows (in particular, V_Experiment_Detail_Report_Ex)
**          05/23/2010 grk - create this sproc from common function factored out of UpdateDataPackageItems and UpdateDataPackageItemsXML
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
    _schemaName text;
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

    _showDebug := Coalesce(_infoOnly, false);

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug);

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
                _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
            End If;

        End If;

        -- Add parent items and associated items to list for items in the list
        -- This process cascades up the DMS hierarchy of tracking entities, but not down
        --
        If _mode = 'add' Then
        -- <add_associated_items>

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
                    WHERE Tmp_DataPackageItems.ItemType = 'Biomaterial' AND Tmp_DataPackageItems.Identifier = TX.Biomaterial_Name AND Tmp_DataPackageItems.DataPackageID = TP.DataPackageID
                )

        End If; -- </add_associated_items>

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

            -- ToDo: Update this to use RAISE INFO

            SELECT *
            FROM Tmp_DataPackageItems
            ORDER BY DataPackageID, ItemType, Identifier;

            DROP TABLE Tmp_DatasetIDsToAdd;
            DROP TABLE Tmp_JobsToAddOrDelete;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Biomaterial operations
        ---------------------------------------------------

        If _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Biomaterial') Then
        -- <delete biomaterial>
            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT 'Biomaterial to delete' AS Biomaterial_Msg, Target.*
                FROM dpkg.t_data_package_biomaterial Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.biomaterial AND
                          Tmp_DataPackageItems.ItemType = 'Biomaterial'
            Else
                DELETE Target
                FROM dpkg.t_data_package_biomaterial Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.biomaterial AND
                          Tmp_DataPackageItems.ItemType = 'Biomaterial'
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _deleteCount;
                    _actionMsg := format('Deleted %s biomaterial %s', _deleteCount, public.check_plural(_deleteCount, 'item', 'items'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </delete biomaterial>

        If _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Biomaterial') Then
        -- <comment biomaterial>
            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT 'Update biomaterial comment' AS Item_Type,
                       _comment AS New_Comment, *
                FROM dpkg.t_data_package_biomaterial Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.biomaterial AND
                          Tmp_DataPackageItems.ItemType = 'Biomaterial'
            Else
                UPDATE dpkg.t_data_package_biomaterial
                SET package_comment = _comment
                FROM Tmp_DataPackageItems Src
                WHERE Src.DataPackageID = dpkg.t_data_package_biomaterial.Data_Package_ID AND
                      Src.Identifier = dpkg.t_data_package_biomaterial.Name AND
                      Src.ItemType = 'Biomaterial'
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                If _updateCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _updateCount;
                    _actionMsg := format('Updated the comment for %s biomaterial %s', _updateCount, public.check_plural(_updateCount, 'item', 'items'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </comment biomaterial>

        If _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Biomaterial') Then
        -- <add biomaterial>

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

                -- ToDo: Update this to use RAISE INFO

                SELECT DISTINCT Tmp_DataPackageItems.DataPackageID,
                                'New Biomaterial' AS Item_Type,
                                TX.ID,
                                _comment AS Comment,
                                TX.Name,
                                TX.Campaign,
                                TX.Created,
                                TX.Type
                FROM Tmp_DataPackageItems
                     INNER JOIN V_Biomaterial_List_Report_2 TX
                       ON Tmp_DataPackageItems.Identifier = TX.Name

                WHERE Tmp_DataPackageItems.ItemType = 'Biomaterial'
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
                FROM
                    Tmp_DataPackageItems
                    INNER JOIN V_Biomaterial_List_Report_2 TX
                    ON Tmp_DataPackageItems.Identifier = TX.name
                WHERE Tmp_DataPackageItems.ItemType = 'Biomaterial'
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _insertCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _insertCount;
                    _actionMsg := format('Added %s biomaterial %s', _insertCount, public.check_plural(_insertCount, 'item', 'items'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </add biomaterial>

        ---------------------------------------------------
        -- EUS Proposal operations
        ---------------------------------------------------

        If _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'EUSProposal') Then
        -- <delete EUS Proposals>
            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT 'EUS Proposal to delete' AS EUS_Proposal_Msg, Target.*
                FROM dpkg.t_data_package_eus_proposals Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.proposal_id AND
                          Tmp_DataPackageItems.ItemType = 'EUSProposal'
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
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </delete EUS Proposal>

        If _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'EUSProposal') Then
        -- <comment EUS Proposals>
            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT 'Update EUS Proposal comment' AS Item_Type,
                       _comment AS New_Comment,
                       Target.*
                FROM T_Data_Package_EUS_Proposal Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.Data_Package_ID AND
                          Tmp_DataPackageItems.Identifier = Target.Proposal_ID AND
                          Tmp_DataPackageItems.ItemType = 'EUSProposal'
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
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </comment EUS Proposals>

        If _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'EUSProposal') Then
        -- <add EUS Proposals>

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

                -- ToDo: Update this to use RAISE INFO

                SELECT DISTINCT Tmp_DataPackageItems.DataPackageID,
                                'New EUS Proposal' AS Item_Type,
                                TX.ID,
                                _comment AS Comment
                FROM Tmp_DataPackageItems
                     INNER JOIN V_EUS_Proposals_List_Report TX
                       ON Tmp_DataPackageItems.Identifier = TX.ID
                WHERE Tmp_DataPackageItems.ItemType = 'EUSProposal'

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
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </add EUS Proposals>

        ---------------------------------------------------
        -- Experiment operations
        ---------------------------------------------------

        If _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Experiment') Then
        -- <delete experiments>
            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT 'Experiment to delete' AS Experiment_Msg, Target.*
                FROM dpkg.t_data_package_experiments Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.experiment AND
                          Tmp_DataPackageItems.ItemType = 'Experiment'

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
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </delete experiments>

        If _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Experiment') Then
        -- <comment experiments>
            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT 'Update experiment comment' AS Item_Type,
                       _comment AS New_Comment,
                       Target.*
                FROM dpkg.t_data_package_experiments Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.experiment AND
                          Tmp_DataPackageItems.ItemType = 'Experiment'

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
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </comment experiments>

        If _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Experiment') Then
        -- <add experiments>

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

                -- ToDo: Update this to use RAISE INFO

                SELECT DISTINCT
                    Tmp_DataPackageItems.DataPackageID,
                    'New Experiment ID' as Item_Type,
                    TX.ID,
                    _comment AS Comment,
                    TX.Experiment,
                    TX.Created
                FROM
                    Tmp_DataPackageItems
                    INNER JOIN V_Experiment_Detail_Report_Ex TX
                    ON Tmp_DataPackageItems.Identifier = TX.Experiment
                WHERE Tmp_DataPackageItems.ItemType = 'Experiment'
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
                FROM
                    Tmp_DataPackageItems
                    INNER JOIN V_Experiment_Detail_Report_Ex TX
                    ON Tmp_DataPackageItems.Identifier = TX.experiment
                WHERE Tmp_DataPackageItems.ItemType = 'Experiment'
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _insertCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _insertCount;
                    _actionMsg := format('Added %s %s', _insertCount, public.check_plural(_insertCount, 'experiment', 'experiments'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </add experiments>

        ---------------------------------------------------
        -- Dataset operations
        ---------------------------------------------------

        If _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Dataset') Then
        -- <delete datasets>
            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT 'Dataset to delete' AS Dataset_Msg, Target.*
                FROM dpkg.t_data_package_datasets Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.dataset AND
                          Tmp_DataPackageItems.ItemType = 'Dataset'

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
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </delete datasets>

        If _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Dataset') Then
        -- <comment datasets>
            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT 'Update dataset comment' AS Item_Type,
                       _comment AS New_Comment,
                       Target.*
                FROM dpkg.t_data_package_datasets Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.dataset AND
                          Tmp_DataPackageItems.ItemType = 'Dataset'

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
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </comment datasets>

        If _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Dataset') Then
        -- <add datasets>

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

                -- ToDo: Update this to use RAISE INFO

                SELECT DISTINCT Tmp_DataPackageItems.DataPackageID,
                                'New Dataset ID' AS Item_Type,
                                TX.ID,
                                _comment AS Comment,
                                TX.Dataset,
                                TX.Created,
                                TX.Experiment,
                                TX.Instrument
                FROM Tmp_DataPackageItems
                     INNER JOIN V_Dataset_List_Report_2 TX
                       ON Tmp_DataPackageItems.Identifier = TX.Dataset
                WHERE Tmp_DataPackageItems.ItemType = 'Dataset'

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
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </add datasets>

        ---------------------------------------------------
        -- Analysis_job operations
        ---------------------------------------------------

        If _mode = 'delete' And Exists (Select * From Tmp_JobsToAddOrDelete) Then
        -- <delete analysis_jobs>
            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT 'job to delete' AS Job_Msg, *
                FROM dpkg.t_data_package_analysis_jobs Target
                     INNER JOIN Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.data_pkg_id = ItemsQ.DataPackageID AND
                          Target.job = ItemsQ.job
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
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </delete analysis_jobs>

        If _mode = 'comment' And Exists (Select * From Tmp_JobsToAddOrDelete) Then
        -- <comment analysis_jobs>
            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT 'Update job comment' AS Item_Type,
                       _comment AS New_Comment,
                       Target.*
                FROM dpkg.t_data_package_analysis_jobs Target
                     INNER JOIN Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.data_pkg_id = ItemsQ.DataPackageID AND
                          Target.job = ItemsQ.job
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
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </comment analysis_jobs>

        If _mode = 'add' And Exists (Select * From Tmp_JobsToAddOrDelete) Then
        -- <add analysis_jobs>

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

                -- ToDo: Update this to use RAISE INFO

                SELECT DISTINCT ItemsQ.DataPackageID,
                                'New Job' AS Item_Type,
                                TX.Job,
                                _comment AS Comment,
                                TX.Created,
                                TX.Dataset,
                                TX.Tool
                FROM V_Analysis_Job_List_Report_2 TX
                     INNER JOIN Tmp_JobsToAddOrDelete ItemsQ
                       ON TX.Job = ItemsQ.Job

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
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </add analysis_jobs>

        ---------------------------------------------------
        -- Update item counts for all data packages in the list
        ---------------------------------------------------

        If _itemCountChanged > 0 Then
        -- <UpdateDataPackageItemCounts>
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
                Call update_data_package_item_counts (_packageID);
            END LOOP;

        End If; -- </UpdateDataPackageItemCounts>

        ---------------------------------------------------
        -- Update EUS Info for all data packages in the list
        ---------------------------------------------------
        --
        If _itemCountChanged > 0 Then

            SELECT string_agg(DataPackageID::text, ',' ORDER BY DataPackageID)
            INTO _dataPackageList
            FROM ( SELECT DISTINCT DataPackageID
                   FROM Tmp_DataPackageItems ) AS ListQ;

            Call update_data_package_eus_info (_dataPackageList);
        End If;

        ---------------------------------------------------
        -- Update the last modified date for affected data packages
        ---------------------------------------------------
        --
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
