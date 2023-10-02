--
-- Name: validate_protein_collection_list_for_dataset_table(text, integer, boolean, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.validate_protein_collection_list_for_dataset_table(INOUT _protcollnamelist text DEFAULT ''::text, INOUT _collectioncountadded integer DEFAULT 0, IN _showmessages boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validates that the protein collection names in _protCollNameList include protein collections
**      for the internal standards associated with the datasets listed in temp table Tmp_DatasetList
**
**      The calling procedure must create and populate the temporary table
**
**      CREATE TEMP TABLE Tmp_DatasetList (
**          Dataset_Name text
**      );
**
**      CREATE INDEX IX_Tmp_DatasetList ON Tmp_DatasetList (Dataset_Name);
**
**      This procedure is very similar to procedure validate_protein_collection_list_for_datasets()
**
**  Arguments:
**    _protCollNameList         Comma-separated list of protein collection names
**    _collectionCountAdded     Output: Number of protein collections added
**    _showMessages             When true, update _message to list any protein collections that were added
**    _message                  Status message
**    _returnCode               Return code
**    _showDebug                When true, show the protein collections in _protCollNameList and show the internal standards for the datasets in Tmp_DatasetList
**
**  Auth:   mem
**  Date:   11/13/2006 mem - Initial revision (Ticket #320)
**          02/08/2007 mem - Updated to use T_Internal_Std_Parent_Mixes to determine the protein collections associated with internal standards (Ticket #380)
**          10/11/2007 mem - Expanded protein collection list size to 4000 characters (https://prismtrac.pnl.gov/trac/ticket/545)
**          02/28/2008 grk/mem - Detect duplicate names in protein collection list (https://prismtrac.pnl.gov/trac/ticket/650)
**          07/09/2010 mem - Now auto-adding protein collections associated with the digestion enzyme for the experiments associated with the datasets; this is typically used to add trypsin contaminants to the search
**          09/02/2010 mem - Changed RAISERROR severity level from 10 to 11
**          03/21/2011 mem - Expanded _datasets to varchar(max)
**          03/14/2012 mem - Now preventing both Tryp_Pig_Bov and Tryp_Pig from being included in _protCollNameList
**          10/23/2017 mem - Do not add any enzyme-related protein collections if any of the protein collections in _protCollNameList already include contaminants
**                           - Place auto-added protein collections at the end of _protCollNameList, which is more consistent with the order we get after calling Validate_Analysis_Job_Parameters
**          07/30/2019 mem - Renamed from Validate_Protein_Collection_List_For_Datasets to ValidateProteinCollectionListForDatasetTable
**          07/31/2019 mem - Prevent _protCollNameList from containing both HumanContam and Tryp_Pig_Bov
**          07/27/2022 mem - Switch from FileName to Collection_Name when querying pc.V_Protein_Collections_by_Organism
**          07/26/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_list for a comma-separated list
**
*****************************************************/
DECLARE
    _matchCount int;
    _collectionInfo record;
    _collectionWithContaminants text;
    _datasetCountTotal int;
    _experimentCountTotal int;
    _dups text := '';
    _msg text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _formatSpecifierIntStds text;
    _infoHeadIntStds text;
    _infoHeadSeparatorIntStds text;
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------------------

    _protCollNameList     := Trim(Coalesce(_protCollNameList,''));
    _collectionCountAdded := 0;
    _showMessages         := Coalesce(_showMessages, true);
    _showDebug            := Coalesce(_showDebug, false);

    --------------------------------------------------------------
    -- Create the required temporary tables
    --------------------------------------------------------------

    CREATE TEMP TABLE Tmp_IntStds (
        Internal_Std_Mix_ID int NOT NULL,
        Protein_Collection_Name citext NOT NULL,
        Dataset_Count int NOT NULL,
        Experiment_Count int NOT NULL,
        Enzyme_Contaminant_Collection int NOT NULL
    );

    CREATE TEMP TABLE Tmp_ProteinCollections (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Protein_Collection_Name citext NOT NULL,
        Collection_Appended int NOT NULL
    );

    CREATE TEMP TABLE Tmp_ProteinCollectionsToAdd (
        UniqueID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Protein_Collection_Name citext NOT NULL,
        Dataset_Count int NOT NULL,
        Experiment_Count int NOT NULL,
        Enzyme_Contaminant_Collection int NOT NULL
    );

    --------------------------------------------------------------
    -- Populate Tmp_ProteinCollections with the protein collections in _protCollNameList
    --------------------------------------------------------------

    INSERT INTO Tmp_ProteinCollections (Protein_Collection_Name, Collection_Appended)
    SELECT Value, 0 AS Collection_Appended
    FROM public.parse_delimited_list(_protCollNameList);

    --------------------------------------------------------------
    -- Look for duplicates in Tmp_ProteinCollections
    -- If found, remove them
    --------------------------------------------------------------

    SELECT string_agg(CountQ.Protein_Collection_Name, ', ' ORDER BY CountQ.Protein_Collection_Name)
    INTO _dups
    FROM (
        SELECT Protein_Collection_Name
        FROM Tmp_ProteinCollections
        GROUP BY Protein_Collection_Name
        HAVING COUNT(*) > 1) CountQ;

    If Coalesce(_dups, '') <> '' Then

        RAISE INFO 'There were duplicate names in the protein collections list, will auto remove: %', _dups;

        DELETE FROM Tmp_ProteinCollections
        WHERE NOT Entry_ID IN ( SELECT MIN(Entry_ID) AS IDToKeep
                                FROM Tmp_ProteinCollections
                                GROUP BY Protein_Collection_Name );

    End If;

    If _showDebug Then

        RAISE INFO '';

        _formatSpecifier := '%-30s %-19s %-80s %-19s';

        _infoHead := format(_formatSpecifier,
                            'Table_Name',
                            'Entry_ID',
                            'Protein_Collection_Name',
                            'Collection_Appended'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------------------------',
                                     '-------------------',
                                     '--------------------------------------------------------------------------------',
                                     '-------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT 'Tmp_ProteinCollections' As Table_Name,
                   Entry_ID,
                   Protein_Collection_Name,
                   Collection_Appended
            FROM Tmp_ProteinCollections
            ORDER BY Entry_ID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Table_Name,
                                _previewData.Entry_ID,
                                _previewData.Protein_Collection_Name,
                                _previewData.Collection_Appended
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    --------------------------------------------------------------
    -- Populate Tmp_IntStds with any protein collections associated
    -- with the enzymes for the experiments of the datasets in Tmp_DatasetList
    -- These are typically the contaminant collections like Tryp_Pig_Bov
    --------------------------------------------------------------

    If _showDebug Then
        -- RAISE INFO '%: Populate Tmp_IntStds using t_dataset, t_experiments, and t_enzymes', Clock_Timestamp()::time;
    End If;

    INSERT INTO Tmp_IntStds( Internal_Std_Mix_ID,
                             Protein_Collection_Name,
                             Dataset_Count,
                             Experiment_Count,
                             Enzyme_Contaminant_Collection )
    SELECT DISTINCT Internal_Std_Mix_ID,
                    protein_collection_name,
                    Dataset_Count,
                    Experiment_Count,
                    Enzyme_Contaminant_Collection
    FROM ( SELECT -1 AS Internal_Std_Mix_ID,
                  Coalesce(Enz.protein_collection_name, '') AS Protein_Collection_Name,
                  COUNT(DISTINCT DS.dataset) AS Dataset_Count,
                  COUNT(DISTINCT E.exp_id) AS Experiment_Count,
                  1 AS Enzyme_Contaminant_Collection
            FROM Tmp_DatasetList
                INNER JOIN t_dataset DS
                    ON Tmp_DatasetList.Dataset_Name = DS.dataset
                INNER JOIN t_experiments E
                    ON DS.exp_id = E.exp_id
                INNER JOIN t_enzymes Enz
                    ON E.enzyme_id = Enz.enzyme_id
            GROUP BY Coalesce(Enz.protein_collection_name, '')
            ) LookupQ
    WHERE protein_collection_name <> '';

    _formatSpecifierIntStds := '%-30s %-19s %-80s %-13s %-16s %-30s %-30s';

    _infoHeadIntStds := format(_formatSpecifierIntStds,
                               'Table_Name',
                               'Internal_Std_Mix_ID',
                               'Protein_Collection_Name',
                               'Dataset_Count',
                               'Experiment_Count',
                               'Enzyme_Contaminant_Collection',
                               'Comment'
                              );

    _infoHeadSeparatorIntStds := format(_formatSpecifierIntStds,
                                        '----------------------------',
                                        '-------------------',
                                        '--------------------------------------------------------------------------------',
                                        '-------------',
                                        '----------------',
                                        '------------------------------',
                                        '------------------------------'
                                       );

    If Not Exists (SELECT * FROM Tmp_IntStds WHERE Enzyme_Contaminant_Collection > 0) Then
        --------------------------------------------------------------
        -- Nothing was added; no point in looking for protein collections with Includes_Contaminants > 0
        --------------------------------------------------------------

        If _showDebug Then

            If _showDebug Then
                -- RAISE INFO '%: nothing was added; show Tmp_IntStds', Clock_Timestamp()::time;
            End If;

            RAISE INFO '';
            RAISE INFO '%', _infoHeadIntStds;
            RAISE INFO '%', _infoHeadSeparatorIntStds;

            FOR _previewData IN
                SELECT 'Tmp_IntStds' As Table_Name,
                       Internal_Std_Mix_ID,
                       Protein_Collection_Name,
                       Dataset_Count,
                       Experiment_Count,
                       Enzyme_Contaminant_Collection,
                       '' As Comment
                FROM Tmp_IntStds
            LOOP
                _infoData := format(_formatSpecifierIntStds,
                                    _previewData.Table_Name,
                                    _previewData.Internal_Std_Mix_ID,
                                    _previewData.Protein_Collection_Name,
                                    _previewData.Dataset_Count,
                                    _previewData.Experiment_Count,
                                    _previewData.Enzyme_Contaminant_Collection,
                                    _previewData.Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;
    Else
        --------------------------------------------------------------
        -- Check whether any of the protein collections already have contaminants
        --------------------------------------------------------------

        SELECT COUNT(*),
               MIN(PCLocal.Protein_Collection_Name)
        INTO _matchCount, _collectionWithContaminants
        FROM Tmp_ProteinCollections PCLocal
            INNER JOIN pc.V_Protein_Collections_by_Organism PCMaster
            ON PCLocal.Protein_Collection_Name = PCMaster.Collection_Name
        WHERE PCMaster.Includes_Contaminants > 0;

        If Coalesce(_matchCount, 0) > 0 Then

            If _showDebug Then
                RAISE INFO 'Not adding enzyme-associated protein collections (typically contaminant collections) since % already includes contaminants', _collectionWithContaminants;
            End If;

            _message := format('Did not add contaminants since %s already includes contaminant proteins', _collectionWithContaminants);

            -- Remove the contaminant collections
            --
            DELETE FROM Tmp_IntStds
            WHERE Enzyme_Contaminant_Collection > 0;
        End If;
    End If;

    --------------------------------------------------------------
    -- Populate Tmp_IntStds with any internal standards associated
    -- with the datasets in Tmp_DatasetList, including their parent experiments
    --------------------------------------------------------------

    If _showDebug Then
        -- RAISE INFO '%: Add rows to Tmp_IntStds using t_dataset, t_internal_standards, and t_internal_std_parent_mixes', Clock_Timestamp()::time;
    End If;

    INSERT INTO Tmp_IntStds( Internal_Std_Mix_ID,
                             Protein_Collection_Name,
                             Dataset_Count,
                             Experiment_Count,
                             Enzyme_Contaminant_Collection )
    SELECT DSIntStd.internal_standard_id,
           ISPM.protein_collection_name,
           COUNT(DS.dataset_id) AS Dataset_Count,
           0 AS Experiment_Count,
           0 AS Enzyme_Contaminant_Collection
    FROM Tmp_DatasetList
         INNER JOIN t_dataset DS
           ON Tmp_DatasetList.Dataset_Name = DS.dataset
         INNER JOIN t_internal_standards DSIntStd
           ON DS.internal_standard_id = DSIntStd.internal_standard_id
         INNER JOIN t_internal_std_parent_mixes ISPM
           ON DSIntStd.parent_mix_id = ISPM.parent_mix_id
    WHERE char_length(Coalesce(ISPM.protein_collection_name, '')) > 0
    GROUP BY DSIntStd.internal_standard_id, ISPM.protein_collection_name
    UNION
    SELECT DSIntStd.internal_standard_id,
           ISPM.protein_collection_name,
           0 AS Dataset_Count,
           COUNT(DISTINCT E.exp_id) AS Experiment_Count,
           0 AS Enzyme_Contaminant_Collection
    FROM Tmp_DatasetList
         INNER JOIN t_dataset DS
           ON Tmp_DatasetList.Dataset_Name = DS.dataset
         INNER JOIN t_experiments E
           ON DS.exp_id = E.exp_id
         INNER JOIN t_internal_standards DSIntStd
           ON E.internal_standard_id = DSIntStd.internal_standard_id
         INNER JOIN t_internal_std_parent_mixes ISPM
           ON DSIntStd.parent_mix_id = ISPM.parent_mix_id
    WHERE char_length(Coalesce(ISPM.protein_collection_name, '')) > 0
    GROUP BY DSIntStd.internal_standard_id, ISPM.protein_collection_name
    UNION
    SELECT DSIntStd.internal_standard_id,
           ISPM.protein_collection_name,
           0 AS Dataset_Count,
           COUNT(DISTINCT E.exp_id) AS Experiment_Count,
           0 AS Enzyme_Contaminant_Collection
    FROM Tmp_DatasetList
         INNER JOIN t_dataset DS
           ON Tmp_DatasetList.Dataset_Name = DS.dataset
         INNER JOIN t_experiments E
           ON DS.exp_id = E.exp_id
         INNER JOIN t_internal_standards DSIntStd
           ON E.post_digest_internal_std_id = DSIntStd.internal_standard_id
         INNER JOIN t_internal_std_parent_mixes ISPM
           ON DSIntStd.parent_mix_id = ISPM.parent_mix_id
    WHERE char_length(Coalesce(ISPM.protein_collection_name, '')) > 0
    GROUP BY DSIntStd.internal_standard_id, ISPM.protein_collection_name
    ORDER BY internal_standard_id;

    If _showDebug Then
        RAISE INFO '';
        -- RAISE INFO '%: Show contents of Tmp_IntStds', Clock_Timestamp()::time;

        RAISE INFO '%', _infoHeadIntStds;
        RAISE INFO '%', _infoHeadSeparatorIntStds;

        FOR _previewData IN
            SELECT 'Tmp_IntStds' As Table_Name,
                   Internal_Std_Mix_ID,
                   Protein_Collection_Name,
                   Dataset_Count,
                   Experiment_Count,
                   Enzyme_Contaminant_Collection,
                   '' As Comment
            FROM Tmp_IntStds
        LOOP
            _infoData := format(_formatSpecifierIntStds,
                                _previewData.Table_Name,
                                _previewData.Internal_Std_Mix_ID,
                                _previewData.Protein_Collection_Name,
                                _previewData.Dataset_Count,
                                _previewData.Experiment_Count,
                                _previewData.Enzyme_Contaminant_Collection,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    --------------------------------------------------------------
    -- If Tmp_IntStds contains 'HumanContam' but Tmp_ProteinCollections contains 'Tryp_Pig_Bov',
    -- remove 'HumanContam' from Tmp_IntStds since every protein in 'HumanContam' is also in 'Tryp_Pig_Bov'
    --------------------------------------------------------------

    If Exists ( SELECT *
                FROM Tmp_ProteinCollections
                WHERE Protein_Collection_Name = 'Tryp_Pig_Bov' ) AND
       Exists ( SELECT *
                FROM Tmp_IntStds
                WHERE Protein_Collection_Name = 'HumanContam' ) Then

        DELETE FROM Tmp_IntStds
        WHERE Protein_Collection_Name = 'HumanContam';

        If _showDebug Then

            RAISE INFO '';

            If Exists (SELECT * FROM Tmp_IntStds) Then

                RAISE INFO 'Removed HumanContam from Tmp_IntStds since Tmp_ProteinCollections has Tryp_Pig_Bov';
                RAISE INFO '';

                RAISE INFO '%', _infoHeadIntStds;
                RAISE INFO '%', _infoHeadSeparatorIntStds;

                FOR _previewData IN
                    SELECT 'Tmp_IntStds' As Table_Name,
                           Internal_Std_Mix_ID,
                           Protein_Collection_Name,
                           Dataset_Count,
                           Experiment_Count,
                           Enzyme_Contaminant_Collection,
                           'After removing HumanContam' As Comment
                    FROM Tmp_IntStds
                LOOP
                    _infoData := format(_formatSpecifierIntStds,
                                        _previewData.Table_Name,
                                        _previewData.Internal_Std_Mix_ID,
                                        _previewData.Protein_Collection_Name,
                                        _previewData.Dataset_Count,
                                        _previewData.Experiment_Count,
                                        _previewData.Enzyme_Contaminant_Collection,
                                        _previewData.Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                RAISE INFO 'Tmp_IntStds is empty after removing HumanContam';
            End If;
        End If;

    End If;

    --------------------------------------------------------------
    -- Make sure _protCollNameList contains each of the
    -- Protein_Collection_Name values in Tmp_IntStds
    --------------------------------------------------------------

    INSERT INTO Tmp_ProteinCollectionsToAdd( Protein_Collection_Name,
                                             Dataset_Count,
                                             Experiment_Count,
                                             Enzyme_Contaminant_Collection )
    SELECT I.Protein_Collection_Name,
           SUM(I.Dataset_Count),
           SUM(I.Experiment_Count),
           SUM(Enzyme_Contaminant_Collection)
    FROM Tmp_IntStds I
         LEFT OUTER JOIN Tmp_ProteinCollections PC
           ON I.Protein_Collection_Name = PC.Protein_Collection_Name
    WHERE PC.Protein_Collection_Name IS NULL
    GROUP BY I.Protein_Collection_Name;

    If _showDebug Then

        If Exists (Select * From Tmp_ProteinCollectionsToAdd) Then

            RAISE INFO '';

            _formatSpecifier := '%-30s %-19s %-80s %-13s %-16s %-29s';

            _infoHead := format(_formatSpecifier,
                                'Table_Name',
                                'UniqueID',
                                'Protein_Collection_Name',
                                'Dataset_Count',
                                'Experiment_Count',
                                'Enzyme_Contaminant_Collection'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------------------------',
                                         '-------------------',
                                         '--------------------------------------------------------------------------------',
                                         '-------------',
                                         '----------------',
                                         '-----------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT 'Tmp_ProteinCollectionsToAdd' As Table_Name,
                       UniqueID,
                       Protein_Collection_Name,
                       Dataset_Count,
                       Experiment_Count,
                       Enzyme_Contaminant_Collection
                FROM Tmp_ProteinCollectionsToAdd
                ORDER BY UniqueID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Table_Name,
                                    _previewData.UniqueID,
                                    _previewData.Protein_Collection_Name,
                                    _previewData.Dataset_Count,
                                    _previewData.Experiment_Count,
                                    _previewData.Enzyme_Contaminant_Collection
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        Else
            RAISE INFO 'Tmp_ProteinCollectionsToAdd is empty';
        End If;
    End If;

    If Not Exists (SELECT * FROM Tmp_ProteinCollectionsToAdd) Then
        DROP TABLE Tmp_IntStds;
        DROP TABLE Tmp_ProteinCollections;
        DROP TABLE Tmp_ProteinCollectionsToAdd;
        RETURN;
    End If;

    -- New collections were added to Tmp_ProteinCollectionsToAdd
    -- Now append them to Tmp_ProteinCollections
    -- Note that we first append collections that did not come from digestion enzymes
    --
    INSERT INTO Tmp_ProteinCollections (Protein_Collection_Name, Collection_Appended)
    SELECT Protein_Collection_Name,
           1 AS Collection_Appended
    FROM Tmp_ProteinCollectionsToAdd
    GROUP BY Enzyme_Contaminant_Collection, Protein_Collection_Name
    ORDER BY Enzyme_Contaminant_Collection, Protein_Collection_Name;
    --
    GET DIAGNOSTICS _collectionCountAdded = ROW_COUNT;

    -- Check for the presence of both Tryp_Pig_Bov and Tryp_Pig in Tmp_ProteinCollections
    --
    SELECT COUNT(*)
    INTO _matchCount
    FROM Tmp_ProteinCollections
    WHERE Protein_Collection_Name IN ('Tryp_Pig_Bov', 'Tryp_Pig');

    If Coalesce(_matchCount, 0) = 2 Then
        -- The list has two overlapping contaminant collections; remove one of them
        --
        DELETE FROM Tmp_ProteinCollections
        WHERE Protein_Collection_Name = 'Tryp_Pig';

        _collectionCountAdded := _collectionCountAdded - 1;
    End If;

    -- Check for the presence of both Tryp_Pig_Bov and Human_Contam in Tmp_ProteinCollections
    --
    SELECT COUNT(*)
    INTO _matchCount
    FROM Tmp_ProteinCollections
    WHERE Protein_Collection_Name IN ('Tryp_Pig_Bov', 'HumanContam');

    If Coalesce(_matchCount, 0) = 2 Then
        -- The list has two overlapping contaminant collections; remove one of them
        --
        DELETE FROM Tmp_ProteinCollections
        WHERE Protein_Collection_Name = 'HumanContam';

        _collectionCountAdded := _collectionCountAdded - 1;
    End If;

    --------------------------------------------------------------
    -- Collapse Tmp_ProteinCollections into _protCollNameList
    --
    -- The Order By clause in this query assures that any added
    -- internal standard collections and contaminant collections
    -- are listed last and that the original collection order is preserved
    --
    -- Note that Validate_Analysis_Job_Parameters will call Validate_Protein_Collection_Params,
    -- and that procedure uses Standardize_Protein_Collection_List to order the protein collections in a standard manner,
    -- so the order here is not critical
    --
    -- The standard order is:
    --   Internal Standards, Normal Protein Collections, Contaminant collections
    --------------------------------------------------------------

    SELECT string_agg(Protein_Collection_Name, ',' ORDER BY Collection_Appended ASC, Entry_ID ASC)
    INTO _protCollNameList
    FROM Tmp_ProteinCollections;

    -- Count the total number of datasets and experiments in Tmp_DatasetList
    SELECT COUNT(DS.dataset_id),
           COUNT(DISTINCT E.exp_id)
    INTO _datasetCountTotal, _experimentCountTotal
    FROM Tmp_DatasetList
         INNER JOIN t_dataset DS
           ON Tmp_DatasetList.Dataset_Name = DS.dataset
         INNER JOIN t_experiments E
           ON DS.exp_id = E.exp_id;

    If Not _showMessages Then
        DROP TABLE Tmp_IntStds;
        DROP TABLE Tmp_ProteinCollections;
        DROP TABLE Tmp_ProteinCollectionsToAdd;
        RETURN;
    End If;

    -- Update _message to list the collections added

    FOR _collectionInfo IN
        SELECT UniqueID,
               Protein_Collection_Name,
               Dataset_Count,
               Experiment_Count,
               Enzyme_Contaminant_Collection
        FROM Tmp_ProteinCollectionsToAdd
        ORDER BY UniqueID
    LOOP

        If _collectionInfo.Enzyme_Contaminant_Collection <> 0 Then
            _msg := format('Added enzyme contaminant collection %s', _collectionInfo.Protein_Collection_Name);
        Else
            _msg := format('Added protein collection %s since it is present in', _collectionInfo.Protein_Collection_Name);

            If _collectionInfo.Dataset_Count > 0 Then
                _msg := format('%s %s of %s %s',
                                _msg,
                                _collectionInfo.Dataset_Count,
                                _datasetCountTotal,
                                public.check_plural(_datasetCountTotal, 'dataset', 'datasets'));

            ElsIf _collectionInfo.Experiment_Count > 0 Then
                _msg := format('%s %s of %s %s',
                                _msg,
                                _collectionInfo.Experiment_Count,
                                _experimentCountTotal,
                                public.check_plural(_experimentCountTotal, 'experiment', 'experiments'));

            Else
                -- Both _collectionInfo.Dataset_Count and _collectionInfo.Experiment_Count are 0
                -- This code should not be reached
                _msg := format('%s ? datasets and/or ? experiments (unexpected stats)', _msg);
            End If;

        End If;

        If char_length(_message) > 0 Then
            _message := format('%s; %s', _message, _msg);
        Else
            _message := format('Note: %s', _msg);
        End If;

    END LOOP;

    If _showDebug Then
        RAISE INFO '';
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_IntStds;
    DROP TABLE Tmp_ProteinCollections;
    DROP TABLE Tmp_ProteinCollectionsToAdd;
END
$$;


ALTER PROCEDURE public.validate_protein_collection_list_for_dataset_table(INOUT _protcollnamelist text, INOUT _collectioncountadded integer, IN _showmessages boolean, INOUT _message text, INOUT _returncode text, IN _showdebug boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_protein_collection_list_for_dataset_table(INOUT _protcollnamelist text, INOUT _collectioncountadded integer, IN _showmessages boolean, INOUT _message text, INOUT _returncode text, IN _showdebug boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.validate_protein_collection_list_for_dataset_table(INOUT _protcollnamelist text, INOUT _collectioncountadded integer, IN _showmessages boolean, INOUT _message text, INOUT _returncode text, IN _showdebug boolean) IS 'ValidateProteinCollectionListForDatasetTable';

