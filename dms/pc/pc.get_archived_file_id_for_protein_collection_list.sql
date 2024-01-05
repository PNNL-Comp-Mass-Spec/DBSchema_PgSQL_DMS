--
-- Name: get_archived_file_id_for_protein_collection_list(text, text, integer, integer, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.get_archived_file_id_for_protein_collection_list(IN _proteincollectionlist text, IN _creationoptions text DEFAULT 'seq_direction=forward,filetype=fasta'::text, INOUT _archivedfileid integer DEFAULT 0, INOUT _proteincollectioncount integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Given a series of protein collection names, determine the entry in pc.t_archived_output_files that corresponds to the list
**
**      If an entry is not found, sets _archivedFileID to 0
**
**  Arguments:
**    _proteinCollectionList    Comma-separated list of protein collection names or protein collection IDs
**    _creationOptions          Protein collection creation options, e.g. 'seq_direction=forward,filetype=fasta'
**    _archivedFileID           Output: archived file ID from table pc.t_archived_output_files
**    _proteinCollectionCount   Output: protein collection count
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   06/07/2006
**          07/04/2006 mem - Updated to return the newest Archived File Collection ID when there is more than one possible match
**          08/22/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_list for a comma-separated list
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _proteinCollectionName citext;
    _proteinCollectionListClean text := '';
    _matchFound boolean := false;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------

    _proteinCollectionList  := Trim(Coalesce(_proteinCollectionList, ''));
    _creationOptions        := Trim(Coalesce(_creationOptions, ''));
    _archivedFileID         := 0;
    _proteinCollectionCount := 0;

    If _proteinCollectionList = '' Then
        _message := 'Warning: Protein collection list is empty';
        RETURN;
    End If;

    -----------------------------------------------------
    -- Create some temporary tables
    -----------------------------------------------------

    CREATE TEMP TABLE Tmp_ProteinCollectionList (
        Unique_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        ProteinCollectionName citext NOT NULL,
        Valid boolean NOT NULL
    );

    CREATE TEMP TABLE Tmp_Archived_Output_File_IDs (
        Archived_File_ID int NOT NULL,
        Valid_Member_Count int NOT NULL Default 0
    );

    -----------------------------------------------------
    -- Parse the protein collection names and populate a temporary table
    -- If _proteinCollectionList has any integers, they will be updated to use protein collection names (if found in pc.t_protein_collections)
    -----------------------------------------------------

    INSERT INTO Tmp_ProteinCollectionList (ProteinCollectionName, Valid)
    SELECT DISTINCT Value, False
    FROM public.parse_delimited_list(_proteinCollectionList);

    UPDATE Tmp_ProteinCollectionList
    SET Valid = true
    FROM pc.t_protein_collections PC
    WHERE Tmp_ProteinCollectionList.ProteinCollectionName = PC.collection_name;

    If Exists (SELECT Unique_ID FROM Tmp_ProteinCollectionList WHERE Not Valid) Then
        RAISE INFO '';
        RAISE INFO 'One or more protein collection names not found in pc.t_protein_collections; looking for protein collection IDs';

        UPDATE Tmp_ProteinCollectionList Target
        SET ProteinCollectionName = MatchQ.collection_name,
            Valid = true
        FROM ( SELECT CastQ.Unique_ID,
                      PC.collection_name
               FROM ( SELECT Unique_ID,
                             public.try_cast(ProteinCollectionName, null::int) AS Protein_Collection_ID
                      FROM Tmp_ProteinCollectionList
                    ) CastQ
                    INNER JOIN pc.t_protein_collections PC
                      ON CastQ.Protein_Collection_ID = PC.protein_collection_id
             ) MatchQ
        WHERE Target.Unique_ID = MatchQ.Unique_ID;

        If Found Then
            RAISE INFO 'Converted protein collection ID(s) to protein collection name(s)';

            SELECT string_agg(ProteinCollectionName, ', ' ORDER BY ProteinCollectionName)
            INTO _proteinCollectionList
            FROM Tmp_ProteinCollectionList;
        End If;
    End If;

    If Exists (SELECT Unique_ID FROM Tmp_ProteinCollectionList WHERE Not Valid) Then
        RAISE INFO '';

        If Not Exists (SELECT Unique_ID FROM Tmp_ProteinCollectionList WHERE Valid) Then
            _message := format('No valid protein collections were specified, aborting (%s)', _proteinCollectionList);
            RAISE INFO '%', _message;

            DROP TABLE Tmp_ProteinCollectionList;
            DROP TABLE Tmp_Archived_Output_File_IDs;
            RETURN;
        End If;

        SELECT string_agg(ProteinCollectionName, ', ' ORDER BY ProteinCollectionName)
        INTO _message
        FROM Tmp_ProteinCollectionList
        WHERE Not Valid;

        If Position(', ' In _message) > 0 Then
            _message := format('Unrecognized protein collections: %s', _message);
        Else
            _message := format('Unrecognized protein collection: %s', _message);
        End If;

        RAISE INFO '%', _message;

        DELETE FROM Tmp_ProteinCollectionList
        WHERE Not Valid;

        SELECT string_agg(ProteinCollectionName, ', ' ORDER BY ProteinCollectionName)
        INTO _proteinCollectionList
        FROM Tmp_ProteinCollectionList;
    End If;

    -----------------------------------------------------
    -- Select the first protein collection and count the number of protein collection names present
    -----------------------------------------------------

    _proteinCollectionName := '';
    _proteinCollectionCount := 0;

    SELECT MIN(ProteinCollectionName), COUNT(*)
    INTO _proteinCollectionName, _proteinCollectionCount
    FROM Tmp_ProteinCollectionList;

    If _proteinCollectionCount < 1 Then
        _message := 'Could not find any entries in Tmp_ProteinCollectionList; this is unexpected';
        RAISE WARNING '%', _message;

        DROP TABLE Tmp_ProteinCollectionList;
        DROP TABLE Tmp_Archived_Output_File_IDs;
        RETURN;
    End If;

    -----------------------------------------------------
    -- Query to find the archived output files that include _proteinCollectionName and _creationOptions
    --
    -- Additionally, count the number of protein collections included in each archived output file
    -- and only return the archived output files that contain _proteinCollectionCount collections
    -----------------------------------------------------

    INSERT INTO Tmp_Archived_Output_File_IDs (archived_file_id)
    SELECT AOF.archived_file_id
    FROM pc.t_archived_output_file_collections_xref AOFC INNER JOIN
         pc.t_archived_output_files AOF ON AOFC.archived_file_id = AOF.archived_file_id
    WHERE AOF.archived_file_id IN
            ( SELECT AOF.archived_file_id
              FROM pc.t_archived_output_file_collections_xref AOFC
                   INNER JOIN pc.t_archived_output_files AOF ON
                     AOFC.archived_file_id = AOF.archived_file_id
                   INNER JOIN pc.t_protein_collections PC ON
                     AOFC.protein_collection_id = PC.protein_collection_id
              WHERE PC.collection_name = _proteinCollectionName AND
                    AOF.creation_options = _creationOptions::citext
            )
    GROUP BY AOF.archived_file_id
    HAVING COUNT(*) = _proteinCollectionCount;

    If Not FOUND Then
        _message := 'Warning: Could not find any archived output files';

        If _proteinCollectionCount > 1 Then
            _message := format('%s that contain "%s"', _message, _proteinCollectionList);
        Else
            _message := format('%s that only contain "%s"', _message, _proteinCollectionList);
        End If;

        _message := format('%s and have Creation_Options "%s"', _message, _creationOptions);

        DROP TABLE Tmp_ProteinCollectionList;
        DROP TABLE Tmp_Archived_Output_File_IDs;
        RETURN;
    End If;

    If _proteinCollectionCount = 1 Then
        -----------------------------------------------------
        -- Just one protein collection; query Tmp_Archived_Output_File_IDs to determine the ID
        --
        -- The table should really only contain one row, but updates to the fasta file creation DLL
        -- could result in different versions of the output .fasta file, so we'll always return the newest version
        -----------------------------------------------------

        SELECT Archived_File_ID
        INTO _archivedFileID
        FROM Tmp_Archived_Output_File_IDs
        ORDER BY Archived_File_ID DESC
        LIMIT 1;

        If _message Like 'Unrecognized protein collection%' Then
            _message := format('%s; but found a match for %s', _message, _proteinCollectionList);
        End If;

        DROP TABLE Tmp_ProteinCollectionList;
        DROP TABLE Tmp_Archived_Output_File_IDs;
        RETURN;
    End If;

    -----------------------------------------------------
    -- More than one protein collection; find the best match
    --
    -- Do this by querying Tmp_Archived_Output_File_IDs for
    -- each protein collection in Tmp_ProteinCollectionList
    --
    -- Note that this procedure does not worry about the order of the protein
    -- collections in _proteinCollectionList. If more than one archive exists
    -- with the same collections, but a different ordering, the ID value
    -- for only one of the archives will be returned
    -----------------------------------------------------

    _proteinCollectionCount := 0;

    FOR _proteinCollectionName IN
        SELECT ProteinCollectionName
        FROM Tmp_ProteinCollectionList
        ORDER BY Unique_ID
    LOOP

        UPDATE Tmp_Archived_Output_File_IDs AOF
        SET Valid_Member_Count = Valid_Member_Count + 1
        FROM pc.t_archived_output_file_collections_xref AOFC
             INNER JOIN pc.t_protein_collections PC
               ON AOFC.protein_collection_id = PC.protein_collection_id
        WHERE PC.collection_name = _proteinCollectionName AND
              AOF.archived_file_id = AOFC.archived_file_id;

        _proteinCollectionCount := _proteinCollectionCount + 1;

        If _proteinCollectionCount = 1 Then
            _proteinCollectionListClean := _proteinCollectionName;
        Else
            _proteinCollectionListClean := format('%s,%s', _proteinCollectionListClean, _proteinCollectionName);
        End If;

    END LOOP;

    -----------------------------------------------------
    -- Grab the last entry in Tmp_Archived_Output_File_IDs with Valid_Member_Count equal to _proteinCollectionCount
    --
    -- Note that all of the entries in Tmp_Archived_Output_File_IDs should contain the same number of protein collections,
    -- but only those entries that contain all of the collections in Tmp_ProteinCollectionList will have
    -- Valid_Member_Count equal to _proteinCollectionCount
    -----------------------------------------------------

    SELECT Archived_File_ID
    INTO _archivedFileID
    FROM Tmp_Archived_Output_File_IDs
    WHERE Valid_Member_Count = _proteinCollectionCount
    ORDER BY Archived_File_ID DESC
    LIMIT 1;

    If Not FOUND Then
        _message := format('Warning: Could not find any archived output files that contain "%s" and have Creation_Options "%s"',
                           _proteinCollectionListClean, _creationOptions);

        _archivedFileID := 0;
    ElsIf _message Like 'Unrecognized protein collection%' Then
        _message := format('%s; but found a match for %s', _message, _proteinCollectionList);
    End If;

    DROP TABLE Tmp_ProteinCollectionList;
    DROP TABLE Tmp_Archived_Output_File_IDs;
    RETURN;
END
$$;


ALTER PROCEDURE pc.get_archived_file_id_for_protein_collection_list(IN _proteincollectionlist text, IN _creationoptions text, INOUT _archivedfileid integer, INOUT _proteincollectioncount integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_archived_file_id_for_protein_collection_list(IN _proteincollectionlist text, IN _creationoptions text, INOUT _archivedfileid integer, INOUT _proteincollectioncount integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.get_archived_file_id_for_protein_collection_list(IN _proteincollectionlist text, IN _creationoptions text, INOUT _archivedfileid integer, INOUT _proteincollectioncount integer, INOUT _message text, INOUT _returncode text) IS 'GetArchivedFileIDForProteinCollectionList';

