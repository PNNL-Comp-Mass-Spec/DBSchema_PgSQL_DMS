--
-- Name: update_cached_protein_collection_members(integer, boolean, integer, boolean, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.update_cached_protein_collection_members(IN _collectionidfilter integer DEFAULT 0, IN _updateall boolean DEFAULT false, IN _maxcollectionstoupdate integer DEFAULT 0, IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the information in pc.t_protein_collection_members_cached,
**      which tracks the proteins in each protein collection, including protein name,
**      the first 64 characters of the protein description, the number of residues,
**      and the protein's monoisotopic mass
**
**      By default, only processes new protein collections (with state 1, 2, or 3),
**      and only if the number of rows in pc.t_protein_collection_members_cached
**      differs from the num_proteins value in pc.t_protein_collections
**
**  Arguments:
**    _collectionIdFilter       Optional protein collection ID to filter on
**    _updateAll                When false, only process protein collections where the number of proteins in pc.t_protein_collection_members_cached differs from the num_proteins value in pc.t_protein_collections
**                              Even if _collectionIdFilter is non-zero, if the protein counts match, the protein collection will not be processed; set _updateAll to true to force a specific protein collection to be processed
**                              When true and _collectionIdFilter is 0, will update cached members for all protein collections, regardless of collection state (and this could take a long time)
**    _maxCollectionsToUpdate   Maximum number of protein collections to update
**    _showDebug                When true, show additional progress messages using RAISE INFO
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   06/24/2016 mem - Initial release
**          08/22/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _collectionState int;
    _cacheCount int;
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

    _collectionIdFilter     := Coalesce(_collectionIdFilter, 0);
    _updateAll              := Coalesce(_updateAll, false);
    _maxCollectionsToUpdate := Coalesce(_maxCollectionsToUpdate, 0);
    _showDebug              := Coalesce(_showDebug, false);

    ---------------------------------------------------
    -- Create some temporary tables
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ProteinCollections (
        Protein_Collection_ID int NOT NULL,
        Num_Proteins int NOT NULL,
        Processed boolean NOT NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_ProteinCollections ON Tmp_ProteinCollections ( Protein_Collection_ID );
    CREATE INDEX IX_Tmp_ProteinCollections_Processed ON Tmp_ProteinCollections ( Processed ) INCLUDE (Protein_Collection_ID);

    CREATE TEMP TABLE Tmp_CurrentIDs (
        Protein_Collection_ID int NOT NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_CurrentIDs ON Tmp_CurrentIDs ( Protein_Collection_ID );

    CREATE TEMP TABLE Tmp_ProteinCollectionMembers (
        Protein_Collection_ID int NOT NULL,
        Reference_ID int NOT NULL,
        Protein_ID int NOT NULL
    );

    CREATE INDEX IX_Tmp_ProteinCollectionMembers ON Tmp_ProteinCollectionMembers (Protein_Collection_ID, Reference_ID);

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
        INSERT INTO Tmp_ProteinCollections( Protein_Collection_ID,
                                            Num_Proteins,
                                            Processed )
        SELECT protein_collection_id,
               num_proteins,
               false AS Processed
        FROM pc.t_protein_collections
        WHERE Not collection_state_id IN (0, 5);

    Else
        -- Only add new protein collections
        --
        INSERT INTO Tmp_ProteinCollections( Protein_Collection_ID,
                                            Num_Proteins,
                                            Processed )
        SELECT PC.protein_collection_id,
               PC.num_proteins,
               false AS Processed
        FROM ( SELECT protein_collection_id,
                      num_proteins
               FROM pc.t_protein_collections
               WHERE NOT collection_state_id IN (4, 5)
             ) PC
             LEFT OUTER JOIN ( SELECT protein_collection_id,
                                      COUNT(reference_id) AS cached_protein_count
                               FROM pc.t_protein_collection_members_cached
                               GROUP BY protein_collection_id
                             ) CacheQ
               ON PC.protein_collection_id = CacheQ.protein_collection_id
        WHERE CacheQ.protein_collection_id IS NULL OR
              PC.num_proteins <> cached_protein_count;

    End If;

    If _collectionIdFilter > 0 Then
        DELETE FROM Tmp_ProteinCollections
        WHERE Protein_Collection_ID <> _collectionIdFilter;
    End If;

    If Not Exists (SELECT * FROM Tmp_ProteinCollections) Then
        If _collectionIdFilter <= 0 Then
            _message := 'Tmp_ProteinCollections is empty; nothing to do';
        Else
            SELECT collection_state_id
            INTO _collectionState
            FROM pc.t_protein_collections
            WHERE protein_collection_id = _collectionIdFilter;

            If FOUND Then
                _message := format('Not processing protein collection %s since it has state %s in pc.t_protein_collections; set _updateAll to true to force the cached proteins to be updated', _collectionIdFilter, _collectionState);
            Else
                _message := format('Protein collection %s not found in pc.t_protein_collections', _collectionIdFilter);
            End If;
        End If;

        RAISE INFO '';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_ProteinCollections;
        DROP TABLE Tmp_CurrentIDs;
        DROP TABLE Tmp_ProteinCollectionMembers;
        DROP TABLE Tmp_ProteinCountErrors;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Process the protein collections
    -- Limit the number to process at a time with the goal of updating up to 500,000 records in each batch
    ---------------------------------------------------

    If _showDebug Then
        SELECT COUNT(*)
        INTO _collectionCount
        FROM Tmp_ProteinCollections;

        RAISE INFO '';
        RAISE INFO 'Processing % protein %', _collectionCount, public.check_plural(_collectionCount, 'collection', 'collections');
    End If;

    WHILE true
    LOOP
        TRUNCATE TABLE Tmp_CurrentIDs;
        TRUNCATE TABLE Tmp_ProteinCollectionMembers;

        If _showDebug Then
            RAISE INFO '';
            RAISE INFO 'Selecting protein collections to process in a batch';
        End If;

        -- Find the next set of collections to process
        -- The goal is to process up to 500,000 proteins
        --
        INSERT INTO Tmp_CurrentIDs( Protein_Collection_ID )
        SELECT PC.Protein_Collection_ID
        FROM Tmp_ProteinCollections PC
             INNER JOIN ( SELECT Protein_Collection_ID,
                                 Num_Proteins
                          FROM Tmp_ProteinCollections
                          WHERE NOT Processed
                          ORDER BY Protein_Collection_ID
                        ) SumQ
               ON SumQ.Protein_Collection_ID <= PC.Protein_Collection_ID
        WHERE NOT PC.Processed
        GROUP BY PC.Protein_Collection_ID
        HAVING SUM(SumQ.Num_Proteins) < 500000;

        If Not Exists (SELECT * FROM Tmp_CurrentIDs) Then
            If _showDebug Then
                RAISE INFO 'Match not found using SUM(Num_Proteins) < 500000; select the next available protein collection';
            End If;

            -- The next available protein collection has over 500,000 proteins
            --
            INSERT INTO Tmp_CurrentIDs (Protein_Collection_ID)
            SELECT Protein_Collection_ID
            FROM Tmp_ProteinCollections
            WHERE Not Processed
            ORDER BY Protein_Collection_ID
            LIMIT 1;

            If Not FOUND Then
                If _showDebug Then
                    RAISE INFO '';
                    RAISE INFO 'Match not found using SUM(Num_Proteins) < 500000, and no unprocessed protein collections were found; this message shouldn''t normally be seen due to a check below that looks for unprocessed protein collections';
                End If;

                -- Break out of the while loop
                EXIT;
            End If;
        End If;

        If _maxCollectionsToUpdate > 0 Then
            -- Too many candidate collections; delete the extras
            --
            If _showDebug Then
                RAISE INFO 'Too many collections in the batch; deleting extras';
            End If;

            DELETE FROM Tmp_CurrentIDs
            WHERE NOT Protein_Collection_ID IN ( SELECT Protein_Collection_ID
                                                 FROM Tmp_CurrentIDs
                                                 ORDER BY Protein_Collection_ID
                                                 LIMIT _maxCollectionsToUpdate);
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
        FROM Tmp_CurrentIDs;

        If _currentRangeCount = 0 Then

            If _showDebug Then
                RAISE INFO '';
                RAISE INFO 'All collections have been processed (this message shouldn''t normally be seen due to a check below that looks for unprocessed protein collections)';
            End If;

            -- Break out of the while loop
            EXIT;
        End If;

        _currentRange := format('%s protein %s (%s to %s)',
                                _currentRangeCount, public.check_plural(_currentRangeCount, 'collection ', 'collections'),
                                _currentRangeStart, _currentRangeEnd);

        RAISE INFO 'Processing %', _currentRange;

        ---------------------------------------------------
        -- Cache the protein collection members in temp table Tmp_ProteinCollectionMembers
        -- This is required to avoid a complete table scan of table pc.t_protein_collection_members in the MERGE and DELETE queries below
        ---------------------------------------------------

        INSERT INTO Tmp_ProteinCollectionMembers( Protein_Collection_ID,
                                                  Reference_ID,
                                                  Protein_ID )
        SELECT PCM.protein_collection_id,
               PCM.original_reference_id,
               PCM.protein_id
        FROM pc.t_protein_collection_members PCM
             INNER JOIN Tmp_CurrentIDs C
               ON PCM.protein_collection_id = C.protein_collection_id;
        --
        GET DIAGNOSTICS _cacheCount = ROW_COUNT;

        If _showDebug Then
            RAISE INFO 'Cached % proteins in Tmp_ProteinCollectionMembers', _cacheCount;
        End If;

        ---------------------------------------------------
        -- Add/update data for protein collections in Tmp_CurrentIDs
        ---------------------------------------------------

        MERGE INTO pc.t_protein_collection_members_cached AS t
        USING ( SELECT PCM.protein_collection_id,
                       ProtName.reference_id,
                       ProtName.name AS protein_name,
                       RTrim(Substring(ProtName.description, 1, 64)) AS description,
                       Prot.length AS residue_count,
                       Prot.monoisotopic_mass,
                       PCM.protein_id
                FROM Tmp_ProteinCollectionMembers PCM
                     INNER JOIN pc.t_proteins Prot
                       ON PCM.protein_id = Prot.protein_id
                     INNER JOIN pc.t_protein_names ProtName
                       ON PCM.protein_id = ProtName.protein_id AND
                          PCM.reference_id = ProtName.reference_id
        ) As s
        ON ( t.protein_collection_id = s.protein_collection_id AND t.reference_id = s.reference_id)
        WHEN MATCHED AND (
            t.protein_name <> s.protein_name OR
            t.residue_count <> s.residue_count OR
            t.protein_id <> s.protein_id OR
            t.description IS DISTINCT FROM s.description OR
            t.monoisotopic_mass IS DISTINCT FROM s.monoisotopic_mass
            )
        THEN UPDATE SET
            protein_name = s.protein_name,
            description = s.description,
            residue_count = s.residue_count,
            monoisotopic_mass = s.monoisotopic_mass,
            protein_id = s.protein_id
        WHEN NOT MATCHED THEN
            INSERT(protein_collection_id, reference_id, protein_name, description, residue_count, monoisotopic_mass, protein_id)
            VALUES(s.protein_collection_id, s.reference_id, s.protein_name, s.description, s.residue_count, s.monoisotopic_mass, s.protein_id)
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

        If _showDebug Then
            RAISE INFO 'Deleting extra rows';
        End If;

        DELETE FROM pc.t_protein_collection_members_cached Target
        WHERE target.protein_collection_id IN ( SELECT protein_collection_id FROM Tmp_CurrentIDs ) AND
              NOT EXISTS ( SELECT true
                           FROM pc.t_protein_collection_members_cached PCM
                                INNER JOIN Tmp_CurrentIDs C
                                  ON PCM.protein_collection_id = C.protein_collection_id
                                INNER JOIN Tmp_ProteinCollectionMembers M
                                  ON PCM.protein_collection_id = M.protein_collection_id AND
                                     PCM.reference_id = M.reference_id
                           WHERE Target.protein_collection_id = PCM.protein_collection_id AND
                                 Target.reference_id = PCM.reference_id );
        --
        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

        If _deleteCount > 0 Then
            _statusMsg := format('Deleted %s extra %s from pc.t_protein_collection_members_cached for %s',
                                 _deleteCount, public.check_plural(_deleteCount, 'row', 'rows'), _currentRange);

            RAISE INFO '%', _statusMsg;
            CALL public.post_log_entry ('Normal', _statusMsg, 'Update_Cached_Protein_Collection_Members', 'pc');
        ElsIf _showDebug Then
            RAISE INFO 'No extras were found';
        End If;

        ---------------------------------------------------
        -- Update _collectionCountUpdated
        ---------------------------------------------------

        SELECT COUNT(*)
        INTO _collectionCount
        FROM Tmp_CurrentIDs;

        _collectionCountUpdated := _collectionCountUpdated + _collectionCount;

        If _maxCollectionsToUpdate > 0 And _collectionCountUpdated >= _maxCollectionsToUpdate Then
            If _showDebug Then
                RAISE INFO '';
                RAISE INFO 'The maximum number of protein collections to process has been reached: %', _maxCollectionsToUpdate;
            End If;

            -- Break out of the While Loop
            EXIT;
        End If;

        If Not Exists (SELECT Protein_Collection_ID
                       FROM Tmp_ProteinCollections
                       WHERE Not Processed) Then

            If _showDebug Then
                RAISE INFO '';
                RAISE INFO 'All collections have been processed';
            End If;

            -- Break out of the while loop
            EXIT;
       End If;

       COMMIT;
    END LOOP;

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
        DROP TABLE Tmp_ProteinCollectionMembers;
        DROP TABLE Tmp_ProteinCountErrors;
        RETURN;
    End If;

    RAISE INFO '';
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
    DROP TABLE Tmp_ProteinCollectionMembers;
    DROP TABLE Tmp_ProteinCountErrors;
END
$$;


ALTER PROCEDURE pc.update_cached_protein_collection_members(IN _collectionidfilter integer, IN _updateall boolean, IN _maxcollectionstoupdate integer, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_protein_collection_members(IN _collectionidfilter integer, IN _updateall boolean, IN _maxcollectionstoupdate integer, IN _showdebug boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.update_cached_protein_collection_members(IN _collectionidfilter integer, IN _updateall boolean, IN _maxcollectionstoupdate integer, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateCachedProteinCollectionMembers';

