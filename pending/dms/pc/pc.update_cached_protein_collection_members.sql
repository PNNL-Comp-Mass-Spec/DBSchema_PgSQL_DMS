--
CREATE OR REPLACE PROCEDURE pc.update_cached_protein_collection_members
(
    _collectionIdFilter int = 0,
    _updateAll boolean = false,
    _maxCollectionsToUpdate int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Updates the information in T_Protein_Collection_Members_Cached
**          By default, only adds new protein collections
**
**  Arguments:
**    _collectionIdFilter       Optional protein collection ID tofilter on
**    _updateAll                When true, update cached members for all protein collections
**    _maxCollectionsToUpdate   Maximum number of protein collections to update
**
**  Auth:   mem
**  Date:   06/24/2016 mem - Initial release
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _mergeCount int;
    _deleteCount int;
    _collectionCount int;
    _statusMsg text;
    _collectionCountUpdated int := 0;
    _currentRangeStart int;
    _currentRangeEnd int;
    _currentRangeCount int;
    _currentRange text := '';
    _countInfo record;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _collectionIdFilter := Coalesce(_collectionIdFilter, 0);
    _updateAll := Coalesce(_updateAll, false);
    _maxCollectionsToUpdate := Coalesce(_maxCollectionsToUpdate, 0);

    ---------------------------------------------------
    -- Create some temporary tables
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ProteinCollections (
        Protein_Collection_ID int NOT NULL,
        NumProteins int NOT NULL,
        Processed boolean NOT NULL
    );

    CREATE INDEX IX_Tmp_ProteinCollections ON Tmp_ProteinCollections ( Protein_Collection_ID );
    CREATE INDEX IX_Tmp_ProteinCollections_Processed ON Tmp_ProteinCollections ( Processed ) INCLUDE (Protein_Collection_ID);

    CREATE TEMP TABLE Tmp_CurrentIDs (
        Protein_Collection_ID int NOT NULL
    );

    CREATE INDEX IX_Tmp_CurrentIDs ON Tmp_CurrentIDs ( Protein_Collection_ID );

    CREATE TEMP TABLE Tmp_ProteinCountErrors (
        Protein_Collection_ID int NOT NULL,
        NumProteinsOld int NOT NULL,
        NumProteinsNew int NOT NULL
    );

    ---------------------------------------------------
    -- Find protein collections to process
    ---------------------------------------------------

    If _updateAll Then
        -- Reprocess all of the protein collections
        --
        INSERT INTO Tmp_ProteinCollections (protein_collection_id, num_proteins, Processed)
        SELECT protein_collection_id, num_proteins, false
        FROM pc.t_protein_collections;

    Else
        -- Only add new protein collections
        --
        INSERT INTO Tmp_ProteinCollections (protein_collection_id, num_proteins, Processed)
        SELECT PC.protein_collection_id,
               PC.num_proteins,
               false As Processed
        FROM (SELECT protein_collection_id, num_proteins
              FROM pc.t_protein_collections
              WHERE NOT collection_state_id IN (4)
             ) PC
             LEFT OUTER JOIN ( SELECT protein_collection_id,
                                      COUNT(reference_id) AS CachedProteinCount
                               FROM pc.t_protein_collection_members_cached
                               GROUP BY protein_collection_id
                             ) CacheQ
               ON PC.protein_collection_id = CacheQ.protein_collection_id
        WHERE CacheQ.protein_collection_id IS NULL OR
              PC.num_proteins <> CachedProteinCount;

    End If;

    If _collectionIdFilter <> 0 Then
        DELETE FROM Tmp_ProteinCollections
        WHERE Protein_Collection_ID <> _collectionIdFilter;
    End If;

    If Not Exists (Select * FROM Tmp_ProteinCollections) Then
        RAISE INFO '%', 'Tmp_ProteinCollections is empty; nothing to do';
    End If;

    ---------------------------------------------------
    -- Process the protein collections
    -- Limit the number to process at a time with the goal of updating up to 500,000 records in each batch
    ---------------------------------------------------

    WHILE true
    LOOP
        TRUNCATE TABLE Tmp_CurrentIDs;

        -- Find the next set of collections to process
        -- The goal is to process up to 500,000 proteins
        --
        INSERT INTO Tmp_CurrentIDs (Protein_Collection_ID)
        SELECT PC.Protein_Collection_ID
        FROM Tmp_ProteinCollections PC INNER JOIN
            (SELECT Protein_Collection_ID, NumProteins
             FROM Tmp_ProteinCollections
             WHERE Not Processed) SumQ ON SumQ.Protein_Collection_ID <= PC.Protein_Collection_ID
        WHERE Not Processed
        GROUP BY PC.Protein_Collection_ID
        HAVING SUM(SumQ.NumProteins) < 500000;

        If Not Exists (Select * From Tmp_CurrentIDs) Then
            -- The next available protein collection has over 500,000 proteins
            --
            INSERT INTO Tmp_CurrentIDs (Protein_Collection_ID)
            SELECT Protein_Collection_ID
            FROM Tmp_ProteinCollections
            WHERE Not Processed
            ORDER BY Protein_Collection_ID
            LIMIT 1;
        End If;

        If _maxCollectionsToUpdate > 0 Then
            -- Too many candidate collections; delete the extras
            --
            DELETE Tmp_CurrentIDs
            WHERE NOT Protein_Collection_ID IN ( SELECT Protein_Collection_ID
                                                 FROM Tmp_CurrentIDs
                                                 ORDER BY Protein_Collection_ID
                                                 LIMIT _maxCollectionsToUpdate)
        End If;

        -- Update the processed flag for the candidates
        --
        UPDATE Tmp_ProteinCollections
        SET Processed = true
        FROM Tmp_CurrentIDs C
        WHERE C.Protein_Collection_ID = Tmp_ProteinCollections.Protein_Collection_ID;

        SELECT COUNT(*),
               MIN(Protein_Collection_ID),
               MAX(Protein_Collection_ID)
        INTO _currentRangeCount, _currentRangeStart, _currentRangeEnd
        FROM Tmp_CurrentIDs

        If _currentRangeCount = 0 Then
            -- All collections have been processed
            -- Break out of the while loop
            EXIT;
        End If;

        _currentRange := format('%s protein %s (%s to %s)',
                            _currentRangeCount, check_plural(_currentRangeCount, 'collection', 'collections'),
                            _currentRangeStart, _currentRangeEnd);

        RAISE INFO 'Processing %', _currentRange;

        ---------------------------------------------------
        -- Add/update data for protein collections in Tmp_CurrentIDs
        ---------------------------------------------------

        MERGE pc.t_protein_collection_members_cached AS t
        USING (
            SELECT PCM.protein_collection_id,
                   ProtName.reference_id,
                   ProtName.name AS Protein_Name,
                   Cast(ProtName.description AS text) AS Description,
                   Prot.length AS Residue_Count,
                   Prot.monoisotopic_mass,
                   Prot.protein_id
            FROM pc.t_protein_collection_members PCM
                 INNER JOIN pc.t_proteins Prot
                   ON PCM.protein_id = Prot.protein_id
                 INNER JOIN pc.t_protein_names ProtName
                   ON PCM.protein_id = ProtName.protein_id AND
                      PCM.original_reference_id = ProtName.reference_id
                 INNER JOIN pc.t_protein_collections PC
                   ON PCM.protein_collection_id = PC.protein_collection_id
            WHERE PCM.protein_collection_id IN (SELECT protein_collection_id FROM Tmp_CurrentIDs)
        ) As s
        ON ( t."protein_collection_id" = s."protein_collection_id" AND t."reference_id" = s."reference_id")
        WHEN MATCHED AND (
            t."protein_name" <> s."protein_name" OR
            t."residue_count" <> s."residue_count" OR
            t."protein_id" <> s."protein_id" OR
            Coalesce( NULLIF(t."description", s."description"),
                    NULLIF(s."description", t."description")) IS NOT NULL OR
            Coalesce( NULLIF(t."monoisotopic_mass", s."monoisotopic_mass"),
                    NULLIF(s."monoisotopic_mass", t."monoisotopic_mass")) IS NOT NULL
            )
        THEN UPDATE SET
            "protein_name" = s."protein_name",
            "description" = s."description",
            "residue_count" = s."residue_count",
            "monoisotopic_mass" = s."monoisotopic_mass",
            "protein_id" = s."protein_id"
        WHEN NOT MATCHED BY TARGET THEN
            INSERT("protein_collection_id", "reference_id", "protein_name", "Description", "Residue_Count", "Monoisotopic_Mass", "Protein_ID")
            VALUES(s."protein_collection_id", s."reference_id", s."protein_name", s."Description", s."Residue_Count", s."Monoisotopic_Mass", s."Protein_ID")
        ;

        GET DIAGNOSTICS _mergeCount = ROW_COUNT;

        If _mergeCount > 0 Then
            _statusMsg := format('Added/updated %s rows for %s', _mergeCount, _currentRange);
            RAISE INFO '%', _statusMsg;
            CALL public.post_log_entry ('Normal', _statusMsg, 'Update_Cached_Protein_Collection_Members', 'pc');
        End If;

        ---------------------------------------------------
        -- Delete any extra rows
        ---------------------------------------------------

        DELETE Target
        FROM pc.t_protein_collection_members_cached Target
           INNER JOIN Tmp_CurrentIDs C
               ON Target.protein_collection_id = C.protein_collection_id
             LEFT OUTER JOIN ( SELECT PCM.protein_collection_id,
                                      PCM.original_reference_id
                               FROM pc.t_protein_collection_members PCM
                                    INNER JOIN Tmp_CurrentIDs C
                                      ON PCM.protein_collection_id = C.protein_collection_id
                              ) FilterQ
               ON Target.protein_collection_id = FilterQ.protein_collection_id AND
                  Target.reference_id = FilterQ.original_reference_id
        WHERE FilterQ.protein_collection_id IS NULL
        --
        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

        If _deleteCount > 0 Then
            _statusMsg := format('Deleted %s extra rows from pc.t_protein_collection_members_cached fo %s', _deleteCount, _currentRange);
            RAISE INFO '%', _statusMsg;
            CALL public.post_log_entry ('Normal', _statusMsg, 'Update_Cached_Protein_Collection_Members', 'pc');
        End If;

        ---------------------------------------------------
        -- Update _collectionCountUpdated
        ---------------------------------------------------

        SELECT COUNT(*)
        INTO _collectionCount
        FROM Tmp_CurrentIDs;

        _collectionCountUpdated := _collectionCountUpdated + _collectionCount;

        If _maxCollectionsToUpdate > 0 And _collectionCountUpdated >= _maxCollectionsToUpdate Then
            -- Break out of the While Loop
            EXIT;
        End If;

    END LOOP; -- </a>

    ---------------------------------------------------
    -- Validate the num_proteins value in pc.t_protein_collections
    ---------------------------------------------------

    INSERT INTO Tmp_ProteinCountErrors( protein_collection_id,
                                        NumProteinsOld,
                                        NumProteinsNew )
    SELECT PC.protein_collection_id,
           PC.num_proteins,
           StatsQ.NumProteinsNew
    FROM pc.t_protein_collections PC
         INNER JOIN ( SELECT protein_collection_id,
                             COUNT(reference_id) AS NumProteinsNew
                      FROM pc.t_protein_collection_members_cached
                      GROUP BY protein_collection_id
                    ) StatsQ
           ON PC.protein_collection_id = StatsQ.protein_collection_id
    WHERE PC.num_proteins <> StatsQ.NumProteinsNew;
    --
    GET DIAGNOSTICS _collectionCount = ROW_COUNT;

    If _collectionCount = 0 Then
        DROP TABLE Tmp_ProteinCollections;
        DROP TABLE Tmp_CurrentIDs;
        DROP TABLE Tmp_ProteinCountErrors;
        RETURN;
    End If;

    RAISE WARNING 'Protein counts changed for % protein %', _collectionCount, public.check_plural(_collectionCount, 'collection', 'collections');

    FOR _countInfo IN
        SELECT protein_collection_id AS CollectionID,
               NumProteinsOld,
               NumProteinsNew
        FROM Tmp_ProteinCountErrors
        ORDER BY Protein_Collection_ID
    LOOP

        UPDATE pc.t_protein_collections
        SET num_proteins = _countInfo.NumProteinsNew
        WHERE protein_collection_id = _countInfo.CollectionID;

        _statusMsg := format('Changed number of proteins from %s to %s for protein collection %s in pc.t_protein_collections',
                                _countInfo.NumProteinsOld, _countInfo.NumProteinsNew, _countInfo.CollectionID);

        RAISE INFO '%', _statusMsg;

        CALL public.post_log_entry ('Warning', _statusMsg, 'Update_Cached_Protein_Collection_Members', 'pc');
    END LOOP;

    DROP TABLE Tmp_ProteinCollections;
    DROP TABLE Tmp_CurrentIDs;
    DROP TABLE Tmp_ProteinCountErrors;
END
$$;

COMMENT ON PROCEDURE pc.update_cached_protein_collection_members IS 'UpdateCachedProteinCollectionMembers';
