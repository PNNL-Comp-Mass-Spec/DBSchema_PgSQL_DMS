--
CREATE OR REPLACE PROCEDURE pc.get_archived_file_id_for_protein_collection_list
(
    _proteinCollectionList text,
    _creationOptions text = 'seq_direction=forward,filetype=fasta',
    INOUT _archivedFileID int = 0,
    INOUT _proteinCollectionCount int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Given a series of protein collection names, determine
**          the entry in T_Archived_Output_Files that corresponds to the list
**
**          If an entry is not found, then sets _archivedFileID to 0
**
**  Auth:   mem
**  Date:   06/07/2006
**          07/04/2006 mem - Updated to return the newest Archived File Collection ID when there is more than one possible match
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _proteinCollectionName text;
    _uniqueID int;
    _continue int;
    _proteinCollectionListClean text := '';
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------
    -- Validate the intputs
    -----------------------------------------------------
    _proteinCollectionList := Trim(Coalesce(_proteinCollectionList, ''));
    _archivedFileID := 0;
    _proteinCollectionCount := 0;

    If char_length(_proteinCollectionList) = 0 Then
        _message := 'Warning: Protein collection list is empty';
        Return;
    End If;

    -----------------------------------------------------
    -- Create some temporary tables
    -----------------------------------------------------
    --
    if exists (select * from dbo.sysobjects where id = object_id(N'[TmpProteinCollectionList]') and OBJECTPROPERTY(id, N'IsUserTable') = 1) Then
    drop table [#TmpProteinCollectionList];
    End If;

    CREATE TABLE dbo.TmpProteinCollectionList (
        Unique_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        ProteinCollectionName text NOT NULL
    )

    if exists (select * from dbo.sysobjects where id = object_id(N'[TmpArchived_Output_File_IDs]') and OBJECTPROPERTY(id, N'IsUserTable') = 1) Then
    drop table [#TmpArchived_Output_File_IDs];
    End If;

    CREATE TABLE dbo.TmpArchived_Output_File_IDs (
        Archived_File_ID int NOT NULL,
        Valid_Member_Count int NOT NULL Default 0
    )

    -----------------------------------------------------
    -- Parse the protein collection names and populate a temporary table
    -----------------------------------------------------
    --
    INSERT INTO TmpProteinCollectionList (ProteinCollectionName)
    SELECT Value
    FROM public.parse_delimited_list(_proteinCollectionList, ',')
    --
    GET DIAGNOSTICS _myRowcount = ROW_COUNT;

    If _myError <> 0 Then
        _message := 'Error parsing the protein collection list: Code = ' || _myError::text;
        Return;
    End If;

    If _myRowcount < 1 Then
        _message := 'Error parsing the protein collection list: could not find any entries';
        Return;
    End If;

    -----------------------------------------------------
    -- Count the number of protein collection names present
    -----------------------------------------------------
    --
    _proteinCollectionName := '';
    _proteinCollectionCount := 0;

    SELECT MIN(ProteinCollectionName), COUNT(*)
    INTO _proteinCollectionName, _proteinCollectionCount
    FROM TmpProteinCollectionList
    --
    GET DIAGNOSTICS _myRowcount = ROW_COUNT;

    If _proteinCollectionCount < 1 Then
        _message := 'Could not find any entries in TmpProteinCollectionList; this is unexpected';
        Return;
    End If;

    -----------------------------------------------------
    -- Query to find the archived output files that include _proteinCollectionName and _creationOptions
    -- Additionally, count the number of protein collections included in each archived output file
    --  and only return the archived output files that contain _proteinCollectionCount collections
    -----------------------------------------------------
    --
    INSERT INTO TmpArchived_Output_File_IDs (archived_file_id)
    SELECT AOF.archived_file_id
    FROM pc.t_archived_output_file_collections_xref AOFC INNER JOIN
         pc.t_archived_output_files AOF ON AOFC.archived_file_id = AOF.archived_file_id
    WHERE (AOF.archived_file_id IN
            (    SELECT AOF.archived_file_id
                FROM pc.t_archived_output_file_collections_xref AOFC INNER JOIN
                     pc.t_archived_output_files AOF ON AOFC.archived_file_id = AOF.archived_file_id INNER JOIN
                     pc.t_protein_collections PC ON AOFC.protein_collection_id = PC.protein_collection_id
                WHERE PC.collection_name = _proteinCollectionName AND AOF.creation_options = _creationOptions)
            )
    GROUP BY AOF.archived_file_id
    HAVING COUNT(*) = _proteinCollectionCount
    --
    GET DIAGNOSTICS _myRowcount = ROW_COUNT;

    If _myError <> 0 Then
        _message := 'Error querying the T_Archived_Output_File tables for the given protein collection list: Code = ' || _myError::text;
        Return;
    End If;

    If _myRowcount < 1 Then
        _message := 'Warning: Could not find any archived output files ';
        If _proteinCollectionCount > 1 Then
            _message := _message || 'that contain "' || _proteinCollectionList || '"';
        Else
            _message := _message || 'that only contain "' || _proteinCollectionName || '"';
        End If;

        _message := _message || ' and have Creation_Options "' || _creationOptions || '"';
        Return;
    End If;

    If _proteinCollectionCount = 1 Then
        -----------------------------------------------------
        -- Just one protein collection; query TmpArchived_Output_File_IDs to determine the ID
        -- (the table should really only contain one row, but updates to the fasta file
        --  creation DLL could result in different versions of the output .fasta file, so
        --  we'll always return the newest version)
        -----------------------------------------------------
        --
        -- Moved to bottom of query: TOP 1
        SELECT Archived_File_ID INTO _archivedFileID
        FROM TmpArchived_Output_File_IDs
        ORDER BY Archived_File_ID Desc
        LIMIT 1;
        --
        GET DIAGNOSTICS _myRowcount = ROW_COUNT;

    Else
    -- <a>
        -----------------------------------------------------
        -- More than one protein collection; find the best match
        -- Do this by querying TmpArchived_Output_File_IDs for
        --  each protein collection in TmpProteinCollectionList
        -- Note that this procedure does not worry about the order of the protein
        --  collections in _proteinCollectionList.  If more than one archive exists
        --  with the same collections, but a different ordering, then the ID value
        --  for only one of the archives will be returned
        -----------------------------------------------------
        --
        _uniqueID := 0;
        _proteinCollectionCount := 0;

        _continue := 1;
        While _continue = 1 Loop
            -- This While loop can probably be converted to a For loop; for example:
            --    For _itemName In
            --        SELECT item_name
            --        FROM TmpSourceTable
            --        ORDER BY entry_id
            --    Loop
            --        ...
            --    End Loop

            SELECT ProteinCollectionName, Unique_ID
            INTO _proteinCollectionName, _uniqueID
            FROM TmpProteinCollectionList
            WHERE Unique_ID > _uniqueID
            ORDER BY Unique_ID
            LIMIT 1;
            --
            GET DIAGNOSTICS _myRowcount = ROW_COUNT;

            If _myRowcount < 1 Then
                _continue := 0;
            Else
            -- <c>
                UPDATE TmpArchived_Output_File_IDs
                SET Valid_Member_Count = Valid_Member_Count + 1
                FROM TmpArchived_Output_File_IDs AOF INNER JOIN

                /********************************************************************************
                ** This UPDATE query includes the target table name in the FROM clause
                ** The WHERE clause needs to have a self join to the target table, for example:
                **   UPDATE #TmpArchived_Output_File_IDs
                **   SET ...
                **   FROM source
                **   WHERE source.id = #TmpArchived_Output_File_IDs.id;
                ********************************************************************************/

                                       ToDo: Fix this query

                     pc.t_archived_output_file_collections_xref AOFC ON AOF.archived_file_id = AOFC.archived_file_id INNER JOIN
                     pc.t_protein_collections PC ON AOFC.protein_collection_id = PC.protein_collection_id
                WHERE PC.collection_name = _proteinCollectionName;
                --
                GET DIAGNOSTICS _myRowcount = ROW_COUNT;

                _proteinCollectionCount := _proteinCollectionCount + 1;

                If _proteinCollectionCount = 1 Then
                    _proteinCollectionListClean := _proteinCollectionName;
                Else
                    _proteinCollectionListClean := _proteinCollectionListClean || ',' || _proteinCollectionName;
                End If;

            End If; -- </c>
        END LOOP; -- </b>

        -----------------------------------------------------
        -- Grab the last entry in TmpArchived_Output_File_IDs with
        --  Valid_Member_Count equal to _proteinCollectionCount
        -- Note that all of the entries in TmpArchived_Output_File_IDs
        --  should contain the same number of protein collections,
        --  but only those entries that contain all of the collections
        --  in TmpProteinCollectionList will have Valid_Member_Count
        --  equal to _proteinCollectionCount
        -----------------------------------------------------
        --
        -- Moved to bottom of query: TOP 1
        SELECT Archived_File_ID INTO _archivedFileID
        FROM TmpArchived_Output_File_IDs
        WHERE Valid_Member_Count = _proteinCollectionCount
        ORDER BY Archived_File_ID Desc
        LIMIT 1;
        --
        GET DIAGNOSTICS _myRowcount = ROW_COUNT;

        If _myRowcount < 1 Then
            _message := 'Warning: Could not find any archived output files that contain "' || _proteinCollectionListClean || '"';
            _message := _message || ' and have Creation_Options "' || _creationOptions || '"';

            Return;
        End If;
    End If; -- </a>

Done:
    Return _myError
END
$$;

COMMENT ON PROCEDURE pc.get_archived_file_id_for_protein_collection_list IS 'GetArchivedFileIDForProteinCollectionList';
