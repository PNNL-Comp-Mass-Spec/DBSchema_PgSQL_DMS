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
**          ItemType text null,           -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
**          Identifier text null          -- Job ID, Dataset Name or ID, Experiment Name, Cell_Culture Name, or EUSProposal ID
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
**          12/31/2009 mem - Added DISTINCT keyword to the INSERT INTO queries in case the source views include some duplicate rows (in particular, S_V_Experiment_Detail_Report_Ex)
**          05/23/2010 grk - create this sproc from common function factored out of UpdateDataPackageItems and UpdateDataPackageItemsXML
**          12/31/2013 mem - Added support for EUS Proposals
**          09/02/2014 mem - Updated to remove non-numeric items when working with analysis jobs
**          10/28/2014 mem - Added support for adding datasets using dataset IDs; to delete datasets, you must use the dataset name (safety feature)
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          05/18/2016 mem - Fix bug removing duplicate analysis jobs
**                         - Add parameter _infoOnly
**          10/19/2016 mem - Update Tmp_DataPackageItems to use an integer field for data package ID
**                         - Call UpdateDataPackageEUSInfo
**                         - Prevent addition of Biomaterial '(none)'
**          11/14/2016 mem - Add parameter _removeParents
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          04/25/2018 mem - Populate column Dataset_ID in T_Data_Package_Analysis_Jobs
**          06/12/2018 mem - Send _maxLength to AppendToText
**          07/17/2019 mem - Remove .raw and .d from the end of dataset names
**          07/02/2021 mem - Update the package comment for any existing items when _mode is 'add' and _comment is not an empty string
**          07/02/2021 mem - Change the default value for _mode from undefined mode 'update' to 'add'
**          07/06/2021 mem - Add support for dataset IDs when _mode is 'comment' or 'delete'
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          05/18/2022 mem - Use new EUS Proposal column name
**          06/08/2022 mem - Rename package comment field to Package_Comment
**          07/08/2022 mem - Use new synonym name for experiment biomaterial view
**          04/04/2023 mem - Do not add data package placeholder datasets (e.g. dataset DataPackage_3442_TestData)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _itemCountChanged int := 0;
    _actionMsg text;
    _datasetsRemoved text;
    _packageID int;
    _dataPackageList text := '';
    _msgForLog text := ERROR_MESSAGE();
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

    BEGIN TRY

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
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _infoOnly And _myRowCount > 0 Then
                RAISE INFO '%', 'Warning: deleted ' || Cast(_myRowCount as text) || ' job(s) that were not numeric';
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
                     INNER JOIN S_V_Dataset_List_Report_2 DL
                       ON Source.DatasetID = DL.ID

                -- Update the Type of the Dataset IDs so that they will be ignored
                UPDATE Tmp_DataPackageItems
                SET ItemType = 'DatasetID'
                FROM Tmp_DatasetIDsToAdd
                WHERE Tmp_DataPackageItems.Identifier = Tmp_DatasetIDsToAdd.DatasetID::text;

            End If;

            If Exists (SELECT * FROM Tmp_DataPackageItems WHERE ItemType = 'Dataset' And Identifier Like 'DataPackage[_][0-9][0-9]%') Then
                Set @datasetsRemoved = ''

                SELECT string_agg(Identifier, ', ' ORDER BY Identifier)
                INTO _datasetsRemoved
                FROM Tmp_DataPackageItems
                WHERE ItemType = 'Dataset' And Identifier Like 'DataPackage[_][0-9][0-9]%';

                DELETE FROM Tmp_DataPackageItems
                WHERE ItemType = 'Dataset' And Identifier Like 'DataPackage[_][0-9][0-9]%'

                _actionMsg := format('Data packages cannot include placeholder data package datasets; removed "%s"', _datasetsRemoved);
                _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
            End If;

        End If;

        -- Add parent items and associated items to list for items in the list
        -- This process cascades up the DMS hierarchy of tracking entities, but not down
        --
        IF _mode = 'add' Then
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
                INNER JOIN S_V_Analysis_Job_List_Report_2 TX
                  ON J.Job = TX.Job
            WHERE
                NOT EXISTS (
                    SELECT *
                    FROM Tmp_DataPackageItems
                    WHERE Tmp_DataPackageItems.ItemType = 'Dataset' AND Tmp_DataPackageItems.Identifier = TX.Dataset AND Tmp_DataPackageItems.DataPackageID = J.DataPackageID
                )

            -- Add experiments to list that are parents of datasets in the list
            -- (and are not already in the list)
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT DISTINCT
                TP.DataPackageID,
                'Experiment',
                TX.Experiment
            FROM
                Tmp_DataPackageItems TP
                INNER JOIN S_V_Dataset_List_Report_2 TX
                ON TP.Identifier = TX.Dataset
            WHERE
                TP.ItemType = 'Dataset'
                AND NOT EXISTS (
                    SELECT *
                    FROM Tmp_DataPackageItems
                    WHERE Tmp_DataPackageItems.ItemType = 'Experiment' AND Tmp_DataPackageItems.Identifier = TX.Experiment AND Tmp_DataPackageItems.DataPackageID = TP.DataPackageID
                )

            -- Add EUS Proposals to list that are parents of datasets in the list
            -- (and are not already in the list)
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT DISTINCT
                TP.DataPackageID,
                'EUSProposal',
                TX.Proposal
            FROM
                Tmp_DataPackageItems TP
                INNER JOIN S_V_Dataset_List_Report_2 TX
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
                INNER JOIN S_V_Experiment_Biomaterial TX
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
                       INNER JOIN S_V_Analysis_Job_List_Report_2 TX
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
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

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
                        INNER JOIN S_V_Analysis_Job_List_Report_2 TX
                          ON J.Job = TX.Job
                   UNION
                   SELECT DISTINCT TP.DataPackageID,
                                   'Experiment',
                                   TX.Experiment
                   FROM Tmp_DataPackageItems TP
                        INNER JOIN S_V_Dataset_List_Report_2 TX
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
                                   ItemsQ."Type" = 'dataset' AND
                                   ItemsQ.Identifier = Datasets.dataset
                        WHERE Datasets.data_pkg_id IN (SELECT DISTINCT DataPackageID FROM Tmp_DataPackageItems) AND
                              ItemsQ.Identifier IS NULL
                 ) AS ToKeep2
                   ON ToDelete.DataPackageID = ToKeep2.data_pkg_id AND
                      ToDelete.experiment = ToKeep2.experiment
            WHERE ToKeep1.data_pkg_id IS NULL AND
                  ToKeep2.data_pkg_id IS NULL
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            -- Find parent biomaterial that will have no jobs or datasets remaining once we remove the jobs in Tmp_DataPackageItems
            --
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT ToDelete.DataPackageID, ToDelete.ItemType, ToDelete.Cell_Culture_Name
            FROM (
                   -- Biomaterial associated with jobs that we are removing
                   SELECT DISTINCT J.DataPackageID,
                                   'Biomaterial' AS ItemType,
                                   Biomaterial.Cell_Culture_Name
                   FROM Tmp_JobsToAddOrDelete J
                        INNER JOIN S_V_Analysis_Job_List_Report_2 TX
                          ON J.Job = TX.Job
                        INNER JOIN S_V_Experiment_Cell_Culture Biomaterial
                          ON Biomaterial.Experiment_Num = TX.Experiment
                 ) ToDelete
                 LEFT OUTER JOIN (
                        -- Biomaterial associated with the data package; skipping the jobs that we're deleting
                        SELECT DISTINCT biomaterial.biomaterial AS Cell_Culture_Name,
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
                             INNER JOIN S_V_Experiment_Cell_Culture Exp_CC_Map
                               ON Experiments.experiment = Exp_CC_Map.Experiment_Num AND
                                  Exp_CC_Map.Cell_Culture_Name = biomaterial.biomaterial
                             LEFT OUTER JOIN Tmp_JobsToAddOrDelete ItemsQ
                               ON Jobs.data_pkg_id = ItemsQ.DataPackageID AND
                                  Jobs.job = ItemsQ.job
                        WHERE Jobs.data_pkg_id IN (SELECT DISTINCT DataPackageID FROM Tmp_JobsToAddOrDelete) AND
                              ItemsQ.job IS NULL
                 ) AS ToKeep
                   ON ToDelete.DataPackageID = ToKeep.data_pkg_id AND
                      ToDelete.Cell_Culture_Name = ToKeep.Cell_Culture_Name
            WHERE ToKeep.data_pkg_id IS NULL
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        End If;

        ---------------------------------------------------
        -- Possibly preview the items
        ---------------------------------------------------

        If _infoOnly Then
            If Not _mode::citext In ('add', 'comment', 'delete') Then
                SELECT '_mode should be add, comment, or delete; ' || _mode || ' is invalid' As Warning
            End If;

            SELECT *
            FROM Tmp_DataPackageItems
            ORDER BY DataPackageID, ItemType, Identifier
        End If;

        ---------------------------------------------------
        -- Biomaterial operations
        ---------------------------------------------------

        IF _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Biomaterial') Then
        -- <delete biomaterial>
            If _infoOnly Then
                SELECT 'biomaterial to delete' AS Biomaterial_Msg, Target.*
                FROM dpkg.t_data_package_biomaterial Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.biomaterial AND
                          Tmp_DataPackageItems."type" = 'biomaterial'
            Else
                DELETE Target
                FROM dpkg.t_data_package_biomaterial Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.biomaterial AND
                          Tmp_DataPackageItems."type" = 'biomaterial'
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Deleted %s biomaterial %s', _myRowCount, public.check_plural(_myRowCount, 'item', 'items'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </delete biomaterial>

        IF _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Biomaterial') Then
        -- <comment biomaterial>
            If _infoOnly Then
                SELECT 'Update biomaterial comment' AS Item_Type,
                       _comment AS New_Comment, *
                FROM dpkg.t_data_package_biomaterial Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.biomaterial AND
                          Tmp_DataPackageItems."type" = 'biomaterial'
            Else
                UPDATE dpkg.t_data_package_biomaterial
                SET package_comment = _comment
                FROM dpkg.t_data_package_biomaterial Target

                /********************************************************************************
                ** This UPDATE query includes the target table biomaterial in the FROM clause
                ** The WHERE clause needs to have a self join to the target table, for example:
                **   UPDATE dpkg.t_data_package_biomaterial
                **   SET ...
                **   FROM source
                **   WHERE source.id = dpkg.t_data_package_biomaterial.id;
                ********************************************************************************/

                                       ToDo: Fix this query

                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.Data_Package_ID AND
                          Tmp_DataPackageItems.Identifier = Target.Name AND
                          Tmp_DataPackageItems.ItemType = 'Biomaterial'
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Updated the comment for %s biomaterial %s', _myRowCount, public.check_plural(_myRowCount, 'item', 'items'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </comment biomaterial>

        IF _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Biomaterial') Then
        -- <add biomaterial>

            -- Delete extras
            DELETE Tmp_DataPackageItems
            FROM Tmp_DataPackageItems

            /********************************************************************************
            ** This DELETE query includes the target table name in the FROM clause
            ** The WHERE clause needs to have a self join to the target table, for example:
            **   UPDATE Tmp_DataPackageItems
            **   SET ...
            **   FROM source
            **   WHERE source.id = Tmp_DataPackageItems.id;
            **
            ** Delete queries must also include the USING keyword
            ** Alternatively, the more standard approach is to rearrange the query to be similar to
            **   DELETE FROM Tmp_DataPackageItems WHERE id in (SELECT id from ...)
            ********************************************************************************/

                                   ToDo: Fix this query

                 INNER JOIN dpkg.t_data_package_biomaterial TX
                   ON Tmp_DataPackageItems.DataPackageID = TX.data_pkg_id AND
                      Tmp_DataPackageItems.Identifier = TX.biomaterial AND
                      Tmp_DataPackageItems."type" = 'biomaterial'

            If _infoOnly Then
                SELECT DISTINCT Tmp_DataPackageItems.DataPackageID,
                                'New Biomaterial' AS Item_Type,
                                TX.ID,
                                _comment AS [Comment],
                                TX.Name,
                                TX.Campaign,
                                TX.Created,
                                TX.ItemType
                FROM Tmp_DataPackageItems
                     INNER JOIN S_V_Cell_Culture_List_Report_2 TX
                       ON Tmp_DataPackageItems.Identifier = Name

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
                    "type"
                )
                SELECT DISTINCT
                    Tmp_DataPackageItems.DataPackageID,
                    TX.ID,
                    _comment,
                    TX.biomaterial,
                    TX.campaign,
                    TX.created,
                    TX."type"
                FROM
                    Tmp_DataPackageItems
                    INNER JOIN S_V_Cell_Culture_List_Report_2 TX
                    ON Tmp_DataPackageItems.Identifier = biomaterial
                WHERE Tmp_DataPackageItems."type" = 'biomaterial'
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Added %s biomaterial %s', _myRowCount, public.check_plural(_myRowCount, 'item', 'items'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </add biomaterial>

        ---------------------------------------------------
        -- EUS Proposal operations
        ---------------------------------------------------

        IF _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'EUSProposal') Then
        -- <delete EUS Proposals>
            If _infoOnly Then
                SELECT 'EUS Proposal to delete' AS EUS_Proposal_Msg, Target.*
                FROM dpkg.t_data_package_eus_proposals Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.proposal_id AND
                          Tmp_DataPackageItems."Type" = 'EUSProposal'
            Else
                DELETE Target
                FROM dpkg.t_data_package_eus_proposals Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.proposal_id AND
                          Tmp_DataPackageItems."Type" = 'EUSProposal'
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := 'Deleted %s EUS %s', _myRowCount, public.check_plural(_myRowCount, 'proposal', 'proposals'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </delete EUS Proposal>

        IF _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'EUSProposal') Then
        -- <comment EUS Proposals>
            If _infoOnly Then
                SELECT 'Update EUS Proposal comment' AS Item_Type,
                       _comment AS New_Comment,
                       Target.*
                FROM T_Data_Package_EUS_Proposal Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.Data_Package_ID AND
                          Tmp_DataPackageItems.Identifier = Target.Proposal_ID AND
                          Tmp_DataPackageItems."Type" = 'EUSProposal'
            Else
                UPDATE dpkg.t_data_package_eus_proposals
                SET package_comment = _comment
                FROM dpkg.t_data_package_eus_proposals Target

                /********************************************************************************
                ** This UPDATE query includes the target table name in the FROM clause
                ** The WHERE clause needs to have a self join to the target table, for example:
                **   UPDATE dpkg.t_data_package_eus_proposals
                **   SET ...
                **   FROM source
                **   WHERE source.id = dpkg.t_data_package_eus_proposals.id;
                ********************************************************************************/

                                       ToDo: Fix this query

                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.Data_Package_ID AND
                          Tmp_DataPackageItems.Identifier = Target.Proposal_ID AND
                          Tmp_DataPackageItems.ItemType = 'EUSProposal'
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := 'Updated the comment for %s EUS %s', _myRowCount, public.check_plural(_myRowCount, 'proposal', 'proposals'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </comment EUS Proposals>

        IF _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'EUSProposal') Then
        -- <add EUS Proposals>

            -- Delete extras
            DELETE Tmp_DataPackageItems
            FROM Tmp_DataPackageItems

            /********************************************************************************
            ** This DELETE query includes the target table name in the FROM clause
            ** The WHERE clause needs to have a self join to the target table, for example:
            **   UPDATE Tmp_DataPackageItems
            **   SET ...
            **   FROM source
            **   WHERE source.id = Tmp_DataPackageItems.id;
            **
            ** Delete queries must also include the USING keyword
            ** Alternatively, the more standard approach is to rearrange the query to be similar to
            **   DELETE FROM Tmp_DataPackageItems WHERE id in (SELECT id from ...)
            ********************************************************************************/

                                   ToDo: Fix this query

                 INNER JOIN dpkg.t_data_package_eus_proposals TX
                   ON Tmp_DataPackageItems.DataPackageID = TX.data_pkg_id AND
                      Tmp_DataPackageItems.Identifier = TX.proposal_id AND
                      Tmp_DataPackageItems."Type" = 'EUSProposal'

            If _infoOnly Then
                SELECT DISTINCT Tmp_DataPackageItems.DataPackageID,
                                'New EUS Proposal' AS Item_Type,
                                TX.ID,
                                _comment AS [Comment]
                FROM Tmp_DataPackageItems
                     INNER JOIN S_V_EUS_Proposals_List_Report TX
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
                     INNER JOIN S_V_EUS_Proposals_List_Report TX
                       ON Tmp_DataPackageItems.Identifier = TX.ID
                WHERE Tmp_DataPackageItems."Type" = 'EUSProposal'

                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Added %s EUS %s', _myRowCount, public.check_plural(_myRowCount, 'proposal', 'proposals'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </add EUS Proposals>

        ---------------------------------------------------
        -- Experiment operations
        ---------------------------------------------------

        IF _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Experiment') Then
        -- <delete experiments>
            If _infoOnly Then
                SELECT 'experiment to delete' AS Experiment_Msg, Target.*
                FROM dpkg.t_data_package_experiments Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.experiment AND
                          Tmp_DataPackageItems."Type" = 'experiment'

            Else
                DELETE Target
                FROM dpkg.t_data_package_experiments Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                  Tmp_DataPackageItems.Identifier = Target.experiment AND
                          Tmp_DataPackageItems."Type" = 'experiment'
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := 'Deleted %s %s', _myRowCount, public.check_plural(_myRowCount, 'experiment', 'experiments');
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </delete experiments>

        IF _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Experiment') Then
        -- <comment experiments>
            If _infoOnly Then
                SELECT 'Update experiment comment' AS Item_Type,
                       _comment AS New_Comment,
                       Target.*
                FROM dpkg.t_data_package_experiments Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.experiment AND
                          Tmp_DataPackageItems."Type" = 'experiment'

            Else
                UPDATE dpkg.t_data_package_experiments
                SET package_comment = _comment
                FROM dpkg.t_data_package_experiments Target

                /********************************************************************************
                ** This UPDATE query includes the target table name in the FROM clause
                ** The WHERE clause needs to have a self join to the target table, for example:
                **   UPDATE dpkg.t_data_package_experiments
                **   SET ...
                **   FROM source
                **   WHERE source.id = dpkg.t_data_package_experiments.id;
                ********************************************************************************/

                                       ToDo: Fix this query

                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.Data_Package_ID AND
                          Tmp_DataPackageItems.Identifier = Target.Experiment AND
                          Tmp_DataPackageItems.ItemType = 'Experiment'
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Added %s %s', _myRowCount, public.check_plural(_myRowCount, 'experiment', 'experiments'));

                    _actionMsg := 'Updated the comment for ' || Cast(_myRowCount as text) + public.check_plural(_myRowCount, ' experiment', ' experiments');
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </comment experiments>

        IF _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Experiment') Then
        -- <add experiments>

            -- Delete extras
            DELETE Tmp_DataPackageItems
            FROM Tmp_DataPackageItems

            /********************************************************************************
            ** This DELETE query includes the target table name in the FROM clause
            ** The WHERE clause needs to have a self join to the target table, for example:
            **   UPDATE Tmp_DataPackageItems
            **   SET ...
            **   FROM source
            **   WHERE source.id = Tmp_DataPackageItems.id;
            **
            ** Delete queries must also include the USING keyword
            ** Alternatively, the more standard approach is to rearrange the query to be similar to
            **   DELETE FROM Tmp_DataPackageItems WHERE id in (SELECT id from ...)
            ********************************************************************************/

                                   ToDo: Fix this query

                 INNER JOIN dpkg.t_data_package_experiments TX
                   ON Tmp_DataPackageItems.DataPackageID = TX.data_pkg_id AND
                      Tmp_DataPackageItems.Identifier = TX.experiment AND
                      Tmp_DataPackageItems."Type" = 'experiment'

            If _infoOnly Then
                SELECT DISTINCT
                    Tmp_DataPackageItems.DataPackageID,
                    'New Experiment ID' as Item_Type,
                    TX.ID,
                    _comment AS [Comment],
                    TX.Experiment,
                    TX.Created
                FROM
                    Tmp_DataPackageItems
                    INNER JOIN S_V_Experiment_Detail_Report_Ex TX
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
                    INNER JOIN S_V_Experiment_Detail_Report_Ex TX
                    ON Tmp_DataPackageItems.Identifier = TX.experiment
                WHERE Tmp_DataPackageItems."Type" = 'experiment'
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Added %s %s', _myRowCount, public.check_plural(_myRowCount, 'experiment', 'experiments'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </add experiments>

        ---------------------------------------------------
        -- Dataset operations
        ---------------------------------------------------

        IF _mode = 'delete' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Dataset') Then
        -- <delete datasets>
            If _infoOnly Then
                SELECT 'dataset to delete' AS Dataset_Msg, Target.*
                FROM dpkg.t_data_package_datasets Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.dataset AND
                          Tmp_DataPackageItems."Type" = 'dataset'

            Else
                DELETE Target
                FROM dpkg.t_data_package_datasets Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.dataset AND
                          Tmp_DataPackageItems."Type" = 'dataset'
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Deleted %s %s', _myRowCount, public.check_plural(_myRowCount, 'dataset', 'datasets'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </delete datasets>

        IF _mode = 'comment' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Dataset') Then
        -- <comment datasets>
            If _infoOnly Then
                SELECT 'Update dataset comment' AS Item_Type,
                       _comment AS New_Comment,
                       Target.*
                FROM dpkg.t_data_package_datasets Target
                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                          Tmp_DataPackageItems.Identifier = Target.dataset AND
                          Tmp_DataPackageItems."Type" = 'dataset'

            Else
                UPDATE dpkg.t_data_package_datasets
                SET package_comment = _comment
                FROM dpkg.t_data_package_datasets Target

                /********************************************************************************
                ** This UPDATE query includes the target table name in the FROM clause
                ** The WHERE clause needs to have a self join to the target table, for example:
                **   UPDATE dpkg.t_data_package_datasets
                **   SET ...
                **   FROM source
                **   WHERE source.id = dpkg.t_data_package_datasets.id;
                ********************************************************************************/

                                       ToDo: Fix this query

                     INNER JOIN Tmp_DataPackageItems
                       ON Tmp_DataPackageItems.DataPackageID = Target.Data_Package_ID AND
                          Tmp_DataPackageItems.Identifier = Target.Dataset AND
                          Tmp_DataPackageItems.ItemType = 'Dataset'
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Updated the comment for %s %s', _myRowCount, public.check_plural(_myRowCount, 'dataset', 'datasets'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </comment datasets>

        IF _mode = 'add' And Exists (Select * From Tmp_DataPackageItems Where ItemType = 'Dataset') Then
        -- <add datasets>

            -- Delete extras
            DELETE Tmp_DataPackageItems
            FROM Tmp_DataPackageItems

            /********************************************************************************
            ** This DELETE query includes the target table name in the FROM clause
            ** The WHERE clause needs to have a self join to the target table, for example:
            **   UPDATE Tmp_DataPackageItems
            **   SET ...
            **   FROM source
            **   WHERE source.id = Tmp_DataPackageItems.id;
            **
            ** Delete queries must also include the USING keyword
            ** Alternatively, the more standard approach is to rearrange the query to be similar to
            **   DELETE FROM Tmp_DataPackageItems WHERE id in (SELECT id from ...)
            ********************************************************************************/

                                   ToDo: Fix this query

                 INNER JOIN dpkg.t_data_package_datasets TX
                   ON Tmp_DataPackageItems.DataPackageID = TX.data_pkg_id AND
                      Tmp_DataPackageItems.Identifier = TX.dataset AND
                      Tmp_DataPackageItems."Type" = 'dataset'

            If _infoOnly Then
                SELECT DISTINCT Tmp_DataPackageItems.DataPackageID,
                                'New Dataset ID' AS Item_Type,
                                TX.ID,
                                _comment AS [Comment],
                                TX.Dataset,
                                TX.Created,
                                TX.Experiment,
                                TX.Instrument
                FROM Tmp_DataPackageItems
                     INNER JOIN S_V_Dataset_List_Report_2 TX
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
                     INNER JOIN S_V_Dataset_List_Report_2 TX
                       ON Tmp_DataPackageItems.Identifier = TX.dataset
                WHERE Tmp_DataPackageItems."Type" = 'dataset'
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Added %s %s', _myRowCount, public.check_plural(_myRowCount, 'dataset', 'datasets'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </add datasets>

        ---------------------------------------------------
        -- Analysis_job operations
        ---------------------------------------------------

        IF _mode = 'delete' And Exists (Select * From Tmp_JobsToAddOrDelete) Then
        -- <delete analysis_jobs>
            If _infoOnly Then
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
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Deleted %s analysis %s', _myRowCount, public.check_plural(_myRowCount, 'job', 'jobs'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </delete analysis_jobs>

        IF _mode = 'comment' And Exists (Select * From Tmp_JobsToAddOrDelete) Then
        -- <comment analysis_jobs>
            If _infoOnly Then
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
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Updated the comment for %s analysis %s', _myRowCount, public.check_plural(_myRowCount, 'job', 'jobs'));
                    _message := public.append_to_text(_message, _actionMsg, 0, ', ', 512);
                End If;
            End If;
        End If; -- </comment analysis_jobs>

        IF _mode = 'add' And Exists (Select * From Tmp_JobsToAddOrDelete) Then
        -- <add analysis_jobs>

            -- Delete extras
            DELETE Tmp_JobsToAddOrDelete
            FROM Tmp_JobsToAddOrDelete Target

            /********************************************************************************
            ** This DELETE query includes the target table name in the FROM clause
            ** The WHERE clause needs to have a self join to the target table, for example:
            **   UPDATE #Tmp_JobsToAddOrDelete
            **   SET ...
            **   FROM source
            **   WHERE source.id = #Tmp_JobsToAddOrDelete.id;
            **
            ** Delete queries must also include the USING keyword
            ** Alternatively, the more standard approach is to rearrange the query to be similar to
            **   DELETE FROM #Tmp_JobsToAddOrDelete WHERE id in (SELECT id from ...)
            ********************************************************************************/

                                   ToDo: Fix this query

                 INNER JOIN dpkg.t_data_package_analysis_jobs TX
                   ON Target.DataPackageID = TX.data_pkg_id AND
                      Target.job = TX.job

            If _infoOnly Then
                SELECT DISTINCT ItemsQ.DataPackageID,
                                'New Job' AS Item_Type,
                                TX.Job,
                                _comment AS [Comment],
                                TX.Created,
                                TX.Dataset,
                                TX.Tool
                FROM S_V_Analysis_Job_List_Report_2 TX
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
                FROM S_V_Analysis_Job_List_Report_2 TX
                     INNER JOIN Tmp_JobsToAddOrDelete ItemsQ
                       ON TX.job = ItemsQ.job
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
                --
                If _myRowCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _myRowCount;
                    _actionMsg := format('Added %s analysis %s', _myRowCount, public.check_plural(_myRowCount, 'job', 'jobs'));
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
        if _itemCountChanged > 0 Then
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

    END TRY
    BEGIN CATCH
        Call format_error_message _message output, _myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0 Then
            ROLLBACK TRANSACTION;
        End If;

        Call post_log_entry 'Error', _msgForLog, 'UpdateDataPackageItemsUtility'
    END CATCH

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return _myError

    DROP TABLE Tmp_DatasetIDsToAdd;
    DROP TABLE Tmp_JobsToAddOrDelete;
    DROP TABLE Tmp_DataPackageDatasets;
END
$$;

COMMENT ON PROCEDURE dpkg.update_data_package_items_utility IS 'UpdateDataPackageItemsUtility';