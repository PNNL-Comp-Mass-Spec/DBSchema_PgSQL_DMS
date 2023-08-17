--
-- Name: update_data_package_items_utility(text, text, boolean, text, text, text, boolean); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.update_data_package_items_utility(IN _comment text, IN _mode text DEFAULT 'add'::text, IN _removeparents boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates data package items in temp table Tmp_DataPackageItems according to the mode
**
**      CREATE TEMP TABLE Tmp_DataPackageItems (
**          DataPackageID int not null,   -- Data package ID
**          ItemType   citext null,       -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
**          Identifier citext null        -- Job ID, Dataset Name or ID, Experiment Name, Biomaterial Name, or EUSProposal ID
**      );
**
**  Arguments:
**    _comment          Comment to use when the mode is 'add' or 'comment'
**    _mode             'add', 'comment', or 'delete'
**    _removeParents    When true and _mode is 'delete', remove parent datasets and experiments for affected jobs (or experiments for affected datasets)
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
**          08/16/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _badItemTypes text;
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

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _comment       := Trim(Coalesce(_comment, ''));
        _mode          := Trim(Lower(Coalesce(_mode , '')));
        _removeParents := Coalesce(_removeParents, false);

        SELECT string_agg(ItemType, ', ' ORDER BY ItemType)
        INTO _badItemTypes
        FROM ( SELECT DISTINCT ItemType
               FROM Tmp_DataPackageItems
               WHERE Not ItemType IN ('Job', 'Dataset', 'Experiment', 'Biomaterial', 'EUSProposal')
             ) FilterQ;

        If _badItemTypes <> '' Then
            RAISE INFO '';

            If _badItemTypes Like '%,%' Then
                RAISE WARNING 'Invalid item types in temp table Tmp_DataPackageItems: %', _badItemTypes;
            Else
                RAISE WARNING 'Item Type "%" is invalid in temp table Tmp_DataPackageItems', _badItemTypes;
            End If;
        End If;

        CREATE TEMP TABLE Tmp_DatasetIDsToAdd (
            DataPackageID int NOT NULL,
            DatasetID int NOT NULL
        );

        CREATE TEMP TABLE Tmp_JobsToAddOrDelete (
            DataPackageID int not null,            -- Data package ID
            Job int not null
        );

        CREATE INDEX IX_Tmp_JobsToAddOrDelete ON Tmp_JobsToAddOrDelete (Job, DataPackageID);

        -- If working with analysis jobs, populate Tmp_JobsToAddOrDelete with all numeric job entries
        --
        If Exists ( SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Job' ) Then
            DELETE FROM Tmp_DataPackageItems
            WHERE Coalesce(Identifier, '') = '' OR try_cast(Identifier, null::int) Is Null;
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _infoOnly And _deleteCount > 0 Then
                RAISE INFO 'Warning: deleted % job(s) that were not numeric', _deleteCount;
            End If;

            INSERT INTO Tmp_JobsToAddOrDelete( DataPackageID,
                                               Job )
            SELECT DataPackageID,
                   Job
            FROM ( SELECT DataPackageID,
                          try_cast(Identifier, null::int) As Job
                   FROM Tmp_DataPackageItems
                   WHERE ItemType = 'Job' AND
                         NOT DataPackageID IS NULL ) SourceQ
            WHERE NOT Job IS NULL;
        End If;

        If Exists ( SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Dataset' ) Then
            -- Auto-remove .raw and .d from the end of dataset names
            UPDATE Tmp_DataPackageItems
            SET Identifier = Substring(Identifier, 1, char_length(Identifier) - 4)
            WHERE ItemType = 'Dataset' And Tmp_DataPackageItems.Identifier Like '%.raw';

            UPDATE Tmp_DataPackageItems
            SET Identifier = Substring(Identifier, 1, char_length(Identifier) - 2)
            WHERE ItemType = 'Dataset' And Tmp_DataPackageItems.Identifier Like '%.d';

            -- Auto-convert dataset IDs to dataset names
            -- First look for dataset IDs
            INSERT INTO Tmp_DatasetIDsToAdd( DataPackageID,
                                             DatasetID )
            SELECT DataPackageID,
                   DatasetID
            FROM ( SELECT DataPackageID,
                          try_cast(Identifier, null::int) AS DatasetID
                   FROM Tmp_DataPackageItems
                   WHERE ItemType = 'Dataset' AND
                         NOT DataPackageID IS NULL ) SourceQ
            WHERE NOT DatasetID IS NULL;

            If Exists (SELECT DataPackageID FROM Tmp_DatasetIDsToAdd) Then
                -- Add the dataset names
                INSERT INTO Tmp_DataPackageItems( DataPackageID,
                                                  ItemType,
                                                  Identifier )
                SELECT Source.DataPackageID,
                       'Dataset' AS ItemType,
                       DS.Dataset
                FROM Tmp_DatasetIDsToAdd Source
                     INNER JOIN PUBLIC.t_dataset DS
                       ON Source.DatasetID = DS.dataset_id;

                -- Update the Type of the Dataset IDs so that they will be ignored
                UPDATE Tmp_DataPackageItems
                SET ItemType = 'DatasetID'
                FROM Tmp_DatasetIDsToAdd
                WHERE Tmp_DataPackageItems.Identifier = Tmp_DatasetIDsToAdd.DatasetID::text;

            End If;

            If Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Dataset' And Identifier SIMILAR TO 'DataPackage[_][0-9][0-9]%') Then

                SELECT string_agg(Identifier, ', ' ORDER BY Identifier)
                INTO _datasetsRemoved
                FROM Tmp_DataPackageItems
                WHERE ItemType = 'Dataset' And Identifier SIMILAR TO 'DataPackage[_][0-9][0-9]%';

                DELETE FROM Tmp_DataPackageItems
                WHERE ItemType = 'Dataset' And Identifier SIMILAR TO 'DataPackage[_][0-9][0-9]%';

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
            INSERT INTO Tmp_DataPackageItems( DataPackageID,
                                              ItemType,
                                              Identifier )
            SELECT DISTINCT TJ.DataPackageID,
                            'Dataset',
                            DS.Dataset
            FROM Tmp_JobsToAddOrDelete TJ
                 INNER JOIN public.t_analysis_job AJ
                   ON TJ.Job = AJ.Job
                 INNER JOIN public.t_dataset DS
                   ON AJ.dataset_id = DS.dataset_ID
            WHERE NOT EXISTS ( SELECT DataPackageID
                               FROM Tmp_DataPackageItems
                               WHERE Tmp_DataPackageItems.ItemType = 'Dataset' AND
                                     Tmp_DataPackageItems.Identifier = DS.Dataset  AND
                                     Tmp_DataPackageItems.DataPackageID = TJ.DataPackageID ) AND
                  NOT DS.Dataset SIMILAR TO 'DataPackage[_][0-9][0-9]%';

            -- Add experiments to list that are parents of datasets in the list
            -- (and are not already in the list)
            INSERT INTO Tmp_DataPackageItems( DataPackageID,
                                              ItemType,
                                              Identifier )
            SELECT DISTINCT TP.DataPackageID,
                            'Experiment',
                            E.Experiment
            FROM Tmp_DataPackageItems TP
                 INNER JOIN public.t_dataset DS
                   ON TP.Identifier = DS.Dataset
                 INNER JOIN public.t_experiments E
                   ON DS.exp_id = E.exp_id
            WHERE TP.ItemType = 'Dataset' AND
                  NOT EXISTS ( SELECT DataPackageID
                               FROM Tmp_DataPackageItems
                               WHERE Tmp_DataPackageItems.ItemType = 'Experiment' AND
                                     Tmp_DataPackageItems.Identifier = E.Experiment AND
                                     Tmp_DataPackageItems.DataPackageID = TP.DataPackageID );

            -- Add EUS Proposals to list that are parents of datasets in the list
            -- (and are not already in the list)
            INSERT INTO Tmp_DataPackageItems( DataPackageID,
                                              ItemType,
                                              Identifier )
            SELECT DISTINCT TP.DataPackageID,
                            'EUSProposal',
                            RR.eus_proposal_id      -- This is typically a number, but is stored as text
            FROM Tmp_DataPackageItems TP
                 INNER JOIN public.t_dataset DS
                   ON TP.Identifier = DS.Dataset
                 LEFT JOIN public.t_requested_run RR
                   ON ds.dataset_id = rr.dataset_id
            WHERE TP.ItemType = 'Dataset' AND
                  NOT EXISTS ( SELECT DataPackageID
                               FROM Tmp_DataPackageItems
                               WHERE Tmp_DataPackageItems.ItemType = 'EUSProposal' AND
                                     Tmp_DataPackageItems.Identifier = RR.eus_proposal_id AND
                                     Tmp_DataPackageItems.DataPackageID = TP.DataPackageID );

            -- Add biomaterial items to list that are associated with experiments in the list
            -- (and are not already in the list)
            INSERT INTO Tmp_DataPackageItems( DataPackageID,
                                              ItemType,
                                              Identifier )
            SELECT DISTINCT TP.DataPackageID,
                            'Biomaterial',
                            EB.Biomaterial_Name
            FROM Tmp_DataPackageItems TP
                 INNER JOIN V_Experiment_Biomaterial EB
                   ON TP.Identifier = EB.Experiment
            WHERE TP.ItemType = 'Experiment' AND
                  NOT EB.Biomaterial_Name IN ('(none)') AND
                  NOT EXISTS ( SELECT DataPackageID
                               FROM Tmp_DataPackageItems
                               WHERE Tmp_DataPackageItems.ItemType = 'Biomaterial' AND
                                     Tmp_DataPackageItems.Identifier = EB.Biomaterial_Name AND
                                     Tmp_DataPackageItems.DataPackageID = TP.DataPackageID );

        End If;

        If _mode = 'delete' And _removeParents Then
            -- Find Datasets, Experiments, and Biomaterial items that we can safely delete
            -- after deleting the jobs and/or datasets in Tmp_DataPackageItems

            -- Find parent datasets that will have no jobs remaining once we remove the jobs in Tmp_DataPackageItems
            --
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT ToDelete.DataPackageID, ToDelete.ItemType, ToDelete.Dataset
            FROM (
                   -- Datasets associated with jobs that we are removing
                   SELECT DISTINCT TJ.DataPackageID,
                                   'Dataset' AS ItemType,
                                   DS.Dataset AS Dataset
                   FROM Tmp_JobsToAddOrDelete TJ
                        INNER JOIN public.t_analysis_job AJ
                          ON TJ.Job = AJ.Job
                        INNER JOIN public.t_dataset DS
                          ON AJ.dataset_id = DS.dataset_ID
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
            WHERE ToKeep.data_pkg_id IS NULL;

            -- Find parent experiments that will have no jobs or datasets remaining once we remove the jobs in Tmp_DataPackageItems
            --
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT ToDelete.DataPackageID, ToDelete.ItemType, ToDelete.Experiment
            FROM (
                   -- Experiments associated with jobs or datasets that we are removing
                   SELECT DISTINCT TJ.DataPackageID,
                                   'Experiment' AS ItemType,
                                   E.Experiment AS Experiment
                   FROM Tmp_JobsToAddOrDelete TJ
                        INNER JOIN public.t_analysis_job AJ
                          ON TJ.Job = AJ.Job
                        INNER JOIN public.t_dataset DS
                          ON AJ.dataset_id = DS.dataset_ID
                        INNER JOIN public.t_experiments E
                          ON DS.exp_id = E.exp_id
                   UNION
                   SELECT DISTINCT TP.DataPackageID,
                                   'Experiment',
                                   E.Experiment
                   FROM Tmp_DataPackageItems TP
                        INNER JOIN public.t_dataset DS
                          ON TP.Identifier = DS.dataset
                        INNER JOIN public.t_experiments E
                          ON DS.exp_id = E.exp_id
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
                                   ItemsQ.ItemType = 'dataset' AND
                                   ItemsQ.Identifier = Datasets.dataset
                        WHERE Datasets.data_pkg_id IN (SELECT DISTINCT DataPackageID FROM Tmp_DataPackageItems) AND
                              ItemsQ.Identifier IS NULL
                 ) AS ToKeep2
                   ON ToDelete.DataPackageID = ToKeep2.data_pkg_id AND
                      ToDelete.experiment = ToKeep2.experiment
            WHERE ToKeep1.data_pkg_id IS NULL AND
                  ToKeep2.data_pkg_id IS NULL;

            -- Find parent biomaterial that will have no jobs or datasets remaining once we remove the jobs in Tmp_DataPackageItems
            --
            INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
            SELECT ToDelete.DataPackageID, ToDelete.ItemType, ToDelete.Biomaterial_Name
            FROM (
                   -- Biomaterial associated with jobs that we are removing
                   SELECT DISTINCT TJ.DataPackageID,
                                   'Biomaterial' AS ItemType,
                                   Biomaterial.Biomaterial_Name
                   FROM Tmp_JobsToAddOrDelete TJ
                        INNER JOIN public.t_analysis_job AJ
                          ON TJ.Job = AJ.Job
                        INNER JOIN public.t_dataset DS
                          ON AJ.dataset_id = DS.dataset_ID
                        INNER JOIN public.t_experiments E
                          ON DS.exp_id = E.exp_id
                        INNER JOIN V_Experiment_Biomaterial Biomaterial
                          ON Biomaterial.Experiment = E.Experiment
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
            WHERE ToKeep.data_pkg_id IS NULL;

        End If;

        ---------------------------------------------------
        -- Possibly preview the items
        ---------------------------------------------------

        If _infoOnly Then
            If Not _mode In ('add', 'comment', 'delete') Then
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

        If _mode = 'delete' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Biomaterial') Then
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
                DELETE FROM dpkg.t_data_package_biomaterial Target
                WHERE EXISTS
                    ( SELECT 1
                      FROM Tmp_DataPackageItems PkgItems
                      WHERE PkgItems.ItemType = 'biomaterial' AND
                            PkgItems.DataPackageID = Target.data_pkg_id AND
                            PkgItems.Identifier = Target.biomaterial
                    );
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _deleteCount;
                    _actionMsg := format('Deleted %s biomaterial %s', _deleteCount, public.check_plural(_deleteCount, 'item', 'items'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'comment' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Biomaterial') Then
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
                UPDATE dpkg.t_data_package_biomaterial Target
                SET package_comment = _comment
                FROM Tmp_DataPackageItems Src
                WHERE Src.DataPackageID = Target.data_pkg_id AND
                      Src.Identifier = Target.biomaterial AND
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

        If _mode = 'add' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Biomaterial') Then
            -- Delete extras
            DELETE FROM Tmp_DataPackageItems Target
            WHERE EXISTS
                ( SELECT 1
                  FROM Tmp_DataPackageItems PkgItems
                       INNER JOIN dpkg.t_data_package_biomaterial Biomaterial
                         ON PkgItems.DataPackageID = Biomaterial.data_pkg_id AND
                            PkgItems.Identifier = Biomaterial.biomaterial AND
                            PkgItems.ItemType = 'biomaterial'
                  WHERE Target.DataPackageID = PkgItems.DataPackageID AND
                        Target.Identifier = PkgItems.Identifier AND
                        Target.ItemType = PkgItems.Itemtype
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
                                    B.ID As Biomaterial_ID,
                                    B.Type,
                                    B.Name As Biomaterial,
                                    B.Campaign,
                                    _comment AS Comment
                    FROM Tmp_DataPackageItems
                         INNER JOIN V_Biomaterial_List_Report_2 B
                           ON Tmp_DataPackageItems.Identifier = B.Name
                    WHERE Tmp_DataPackageItems.ItemType = 'Biomaterial'
                    ORDER BY Tmp_DataPackageItems.DataPackageID, B.ID
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
                    B.biomaterial_id,
                    _comment,
                    B.biomaterial_name,
                    C.campaign,
                    B.created,
                    btn.biomaterial_type
                FROM Tmp_DataPackageItems
                     INNER JOIN public.t_biomaterial B ON B.biomaterial_name = Tmp_DataPackageItems.Identifier
                     INNER JOIN public.t_biomaterial_type_name btn ON b.biomaterial_type = btn.biomaterial_type_id
                     INNER JOIN public.t_campaign C ON b.campaign_id = c.campaign_id
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

        If _mode = 'delete' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'EUSProposal') Then
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
                DELETE FROM dpkg.t_data_package_eus_proposals Target
                WHERE EXISTS
                    ( SELECT 1
                      FROM Tmp_DataPackageItems PkgItems
                      WHERE PkgItems.ItemType = 'EUSProposal' AND
                            PkgItems.DataPackageID = Target.data_pkg_id AND
                            PkgItems.Identifier = Target.proposal_id
                    );
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _deleteCount;
                    _actionMsg := format('Deleted %s EUS %s', _deleteCount, public.check_plural(_deleteCount, 'proposal', 'proposals'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'comment' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'EUSProposal') Then
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
                           ON Tmp_DataPackageItems.DataPackageID = Target.data_pkg_id AND
                              Tmp_DataPackageItems.Identifier = Target.proposal_id AND
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
                UPDATE dpkg.t_data_package_eus_proposals Target
                SET package_comment = _comment
                FROM Tmp_DataPackageItems Src
                WHERE Src.DataPackageID = Target.data_pkg_id AND
                      Src.Identifier = Target.proposal_id AND
                      Src.ItemType = 'EUSProposal';
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                If _updateCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _updateCount;
                    _actionMsg := format('Updated the comment for %s EUS %s', _updateCount, public.check_plural(_updateCount, 'proposal', 'proposals'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'add' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'EUSProposal') Then
            -- Delete extras
            DELETE FROM Tmp_DataPackageItems Target
            WHERE EXISTS
                ( SELECT 1
                  FROM Tmp_DataPackageItems PkgItems
                       INNER JOIN dpkg.t_data_package_eus_proposals EUP
                         ON PkgItems.DataPackageID = EUP.data_pkg_id AND
                            PkgItems.Identifier = EUP.proposal_id AND
                            PkgItems.ItemType = 'EUSProposal'
                  WHERE Target.DataPackageID = PkgItems.DataPackageID AND
                        Target.Identifier = PkgItems.Identifier AND
                        Target.ItemType = PkgItems.ItemType
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
                                    EUP.Proposal_ID,
                                    Substring(EUP.Title, 1, 90) As Proposal,
                                    _comment As Comment
                    FROM Tmp_DataPackageItems
                         INNER JOIN public.t_eus_proposals EUP
                           ON Tmp_DataPackageItems.Identifier = EUP.proposal_id
                    WHERE Tmp_DataPackageItems.ItemType = 'EUSProposal'
                    ORDER BY Tmp_DataPackageItems.DataPackageID, EUP.ID
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
                                EUP.proposal_id,                -- This is typically a number, but is stored as text
                                _comment
                FROM Tmp_DataPackageItems
                     INNER JOIN public.t_eus_proposals EUP
                       ON Tmp_DataPackageItems.Identifier = EUP.proposal_id
                WHERE Tmp_DataPackageItems.ItemType = 'EUSProposal';
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

        If _mode = 'delete' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Experiment') Then
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
                DELETE FROM dpkg.t_data_package_experiments Target
                WHERE EXISTS
                    ( SELECT 1
                      FROM Tmp_DataPackageItems PkgItems
                      WHERE PkgItems.ItemType = 'Experiment' AND
                            PkgItems.DataPackageID = Target.data_pkg_id AND
                            PkgItems.Identifier = Target.experiment
                    );
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _deleteCount;
                    _actionMsg := format('Deleted %s %s', _deleteCount, public.check_plural(_deleteCount, 'experiment', 'experiments'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'comment' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Experiment') Then
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
                UPDATE dpkg.t_data_package_experiments Target
                SET package_comment = _comment
                FROM Tmp_DataPackageItems Src
                WHERE Src.DataPackageID = Target.data_pkg_id AND
                      Src.Identifier = Target.experiment AND
                      Src.ItemType = 'Experiment';
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                If _updateCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _updateCount;
                    _actionMsg := format('Updated the comment for %s %s', _updateCount, public.check_plural(_updateCount, 'experiment', 'experiments'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'add' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Experiment') Then
            -- Delete extras
            DELETE FROM Tmp_DataPackageItems Target
            WHERE EXISTS
                ( SELECT 1
                  FROM Tmp_DataPackageItems PkgItems
                       INNER JOIN dpkg.t_data_package_experiments DPE
                         ON PkgItems.DataPackageID = DPE.data_pkg_id AND
                            PkgItems.Identifier = DPE.experiment AND
                            PkgItems.ItemType = 'experiment'
                  WHERE Target.DataPackageID = PkgItems.DataPackageID AND
                        Target.Identifier = PkgItems.Identifier AND
                        Target.ItemType = PkgItems.ItemType
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
                                    E.Exp_ID As Experiment_ID,
                                    E.Experiment,
                                    _comment As Comment
                    FROM Tmp_DataPackageItems
                         INNER JOIN public.t_experiments E
                           ON Tmp_DataPackageItems.Identifier = E.Experiment
                    WHERE Tmp_DataPackageItems.ItemType = 'Experiment'
                    ORDER BY Tmp_DataPackageItems.DataPackageID, E.Exp_ID
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
                    E.Exp_ID,
                    _comment,
                    E.experiment,
                    E.created
                FROM Tmp_DataPackageItems
                     INNER JOIN public.t_experiments E
                       ON Tmp_DataPackageItems.Identifier = E.experiment
                WHERE Tmp_DataPackageItems.ItemType = 'Experiment';
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

        If _mode = 'delete' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Dataset') Then
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
                DELETE FROM dpkg.t_data_package_datasets Target
                WHERE EXISTS
                    ( SELECT 1
                      FROM Tmp_DataPackageItems PkgItems
                      WHERE PkgItems.ItemType = 'Dataset' AND
                            PkgItems.DataPackageID = Target.data_pkg_id AND
                            PkgItems.Identifier = Target.dataset
                    );
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _deleteCount;
                    _actionMsg := format('Deleted %s %s', _deleteCount, public.check_plural(_deleteCount, 'dataset', 'datasets'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'comment' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Dataset') Then
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
                UPDATE dpkg.t_data_package_datasets Target
                SET package_comment = _comment
                FROM Tmp_DataPackageItems Src
                WHERE Src.DataPackageID = Target.data_pkg_id AND
                      Src.Identifier = Target.dataset AND
                      Src.ItemType = 'Dataset';
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                If _updateCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _updateCount;
                    _actionMsg := format('Updated the comment for %s %s', _updateCount, public.check_plural(_updateCount, 'dataset', 'datasets'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'add' And Exists (SELECT DataPackageID FROM Tmp_DataPackageItems WHERE ItemType = 'Dataset') Then
            -- Delete extras
            DELETE FROM Tmp_DataPackageItems Target
            WHERE EXISTS
                ( SELECT 1
                  FROM Tmp_DataPackageItems PkgItems
                       INNER JOIN dpkg.t_data_package_datasets DPD
                         ON PkgItems.DataPackageID = DPD.data_pkg_id AND
                            PkgItems.Identifier = DPD.dataset AND
                            PkgItems.ItemType = 'dataset'
                  WHERE Target.DataPackageID = PkgItems.DataPackageID AND
                        Target.Identifier = PkgItems.Identifier AND
                        Target.ItemType = PkgItems.ItemType
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
                                    DS.Dataset_ID,
                                    DS.Dataset,
                                    public.timestamp_text(DS.Created) As Created,
                                    E.Experiment,
                                    InstName.Instrument,
                                    _comment AS Comment
                    FROM Tmp_DataPackageItems
                         INNER JOIN public.t_dataset DS
                           ON Tmp_DataPackageItems.Identifier = DS.Dataset
                         INNER JOIN public.t_experiments E
                           ON DS.exp_id = E.exp_id
                         INNER JOIN public.t_instrument_name InstName
                           ON DS.instrument_id = InstName.instrument_id
                    WHERE Tmp_DataPackageItems.ItemType = 'Dataset'
                    ORDER BY Tmp_DataPackageItems.DataPackageID, DS.dataset_id
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Dataset_ID,
                                        _previewData.Dataset,
                                        _previewData.Created,
                                        _previewData.Experiment,
                                        _previewData.Instrument,
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
                                DS.dataset_id,
                                _comment,
                                DS.dataset,
                                DS.created,
                                E.experiment,
                                InstName.instrument
                FROM Tmp_DataPackageItems
                     INNER JOIN public.t_dataset DS
                       ON Tmp_DataPackageItems.Identifier = DS.dataset
                     INNER JOIN public.t_experiments E
                       ON DS.exp_id = E.exp_id
                     INNER JOIN public.t_instrument_name InstName
                       ON DS.instrument_id = InstName.instrument_id
                WHERE Tmp_DataPackageItems.ItemType = 'Dataset';
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

        If _mode = 'delete' And Exists (SELECT DataPackageID FROM Tmp_JobsToAddOrDelete) Then
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
                DELETE FROM dpkg.t_data_package_analysis_jobs Target
                WHERE EXISTS
                    ( SELECT 1
                      FROM Tmp_JobsToAddOrDelete ItemsQ
                      WHERE ItemsQ.DataPackageID = Target.data_pkg_id AND
                            ItemsQ.job = Target.job
                    );
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                If _deleteCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _deleteCount;
                    _actionMsg := format('Deleted %s analysis %s', _deleteCount, public.check_plural(_deleteCount, 'job', 'jobs'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'comment' And Exists (SELECT DataPackageID FROM Tmp_JobsToAddOrDelete) Then
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
                UPDATE dpkg.t_data_package_analysis_jobs Target
                SET package_comment = _comment
                FROM Tmp_JobsToAddOrDelete ItemsQ
                WHERE ItemsQ.DataPackageID = Target.data_pkg_id AND
                      ItemsQ.job = Target.job;
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                If _updateCount > 0 Then
                    _itemCountChanged := _itemCountChanged + _updateCount;
                    _actionMsg := format('Updated the comment for %s analysis %s', _updateCount, public.check_plural(_updateCount, 'job', 'jobs'));
                    _message := public.append_to_text(_message, _actionMsg, _delimiter => ', ', _maxlength => 512);
                End If;
            End If;
        End If;

        If _mode = 'add' And Exists (SELECT DataPackageID FROM Tmp_JobsToAddOrDelete) Then
            -- Delete extras
            DELETE FROM Tmp_JobsToAddOrDelete Target
            WHERE EXISTS
                ( SELECT 1
                  FROM Tmp_JobsToAddOrDelete PkgJobs
                       INNER JOIN dpkg.t_data_package_analysis_jobs DPJ
                         ON PkgJobs.DataPackageID = DPJ.data_pkg_id AND
                            PkgJobs.job = DPJ.job
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
                                    AJ.Job,
                                    T.Analysis_Tool,
                                    public.timestamp_text(AJ.Created) As Created,
                                    DS.Dataset,
                                    _comment AS Comment
                    FROM Tmp_JobsToAddOrDelete ItemsQ
                         INNER JOIN public.t_analysis_job AJ
                           ON AJ.Job = ItemsQ.Job
                         INNER JOIN public.t_dataset DS
                           ON AJ.dataset_id = DS.dataset_ID
                         INNER JOIN public.t_analysis_tool T
                           ON AJ.analysis_tool_id = T.analysis_tool_id
                    ORDER BY ItemsQ.DataPackageID, AJ.Job
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Data_Pkg_ID,
                                        _previewData.Job,
                                        _previewData.Analysis_Tool,
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
                                AJ.job,
                                _comment,
                                AJ.created,
                                AJ.dataset_id,
                                DS.dataset,
                                T.analysis_tool
                FROM Tmp_JobsToAddOrDelete ItemsQ
                     INNER JOIN public.t_analysis_job AJ
                       ON AJ.Job = ItemsQ.Job
                     INNER JOIN public.t_dataset DS
                       ON AJ.dataset_id = DS.dataset_ID
                     INNER JOIN public.t_analysis_tool T
                       ON AJ.analysis_tool_id = T.analysis_tool_id;
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

            CREATE TEMP TABLE Tmp_DataPackageDatasets (ID int);

            _createdDataPackageDatasetsTable := true;

            INSERT INTO Tmp_DataPackageDatasets (ID)
            SELECT DISTINCT DataPackageID
            FROM Tmp_DataPackageItems;

            FOR _packageID IN
                SELECT ID
                FROM Tmp_DataPackageDatasets
                ORDER BY ID
            LOOP
                CALL dpkg.update_data_package_item_counts (_packageID);
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

            CALL dpkg.update_data_package_eus_info (
                        _dataPackageList,
                        _message => _message,
                        _returncode => _returncode);
        End If;

        ---------------------------------------------------
        -- Update the last modified date for affected data packages
        ---------------------------------------------------

        If _itemCountChanged > 0 Then
            UPDATE dpkg.t_data_package
            SET last_modified = CURRENT_TIMESTAMP
            WHERE data_pkg_id IN ( SELECT DISTINCT DataPackageID FROM Tmp_DataPackageItems );
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

        DROP TABLE Tmp_DatasetIDsToAdd;
        DROP TABLE Tmp_JobsToAddOrDelete;

        If _createdDataPackageDatasetsTable Then
            DROP TABLE Tmp_DataPackageDatasets;
        End If;

        RETURN;

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

    DROP TABLE IF EXISTS Tmp_DatasetIDsToAdd;
    DROP TABLE IF EXISTS Tmp_JobsToAddOrDelete;
    DROP TABLE IF EXISTS Tmp_DataPackageDatasets;
END
$$;


ALTER PROCEDURE dpkg.update_data_package_items_utility(IN _comment text, IN _mode text, IN _removeparents boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_data_package_items_utility(IN _comment text, IN _mode text, IN _removeparents boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.update_data_package_items_utility(IN _comment text, IN _mode text, IN _removeparents boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean) IS 'UpdateDataPackageItemsUtility';

