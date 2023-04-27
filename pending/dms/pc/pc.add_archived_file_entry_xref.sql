--
CREATE OR REPLACE PROCEDURE pc.add_archived_file_entry_xref
(
    _collectionID int,
    _archivedFileID int,
    INOUT _message text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Adds an Archived File Entry to T_Archived_Output_File_Collections_XRef
**        For a given Protein Collection ID
**
**
**
**  Auth:   kja
**  Date:   03/17/2006 - kja
**          03/12/2014 - Now validating _collectionID and _archivedFileID
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _transName text;
BEGIN
    _message := '';

    -------------------------------------------------
    -- Verify the File ID and Collection ID
    ---------------------------------------------------

    If Not Exists (SELECT * FROM pc.t_protein_collections WHERE protein_collection_id = _collectionID) Then
        _message := 'protein_collection_id ' || _collectionID::text || ' not found in pc.t_protein_collections';
        Return 51000
    End If;

    If Not Exists (SELECT * FROM pc.t_archived_output_files WHERE archived_file_id = _archivedFileID) Then
        _message := 'archived_file_id ' || _archivedFileID::text || ' not found in pc.t_archived_output_files';
        Return 51001
    End If;

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'AddArchivedFileEntryXRef';
    begin transaction _transName

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT *
    FROM pc.t_archived_output_file_collections_xref
    WHERE
        (archived_file_id = _archivedFileID AND
         protein_collection_id = _collectionID)

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if _myRowCount = 0 Then

        INSERT INTO pc.t_archived_output_file_collections_xref (archived_file_id, protein_collection_id)
        VALUES (_archivedFileID, _collectionID)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            rollback transaction _transName
            _message := 'Insert operation failed!';
            RAISERROR (_message, 10, 1)
            return 51007
        End If;
    End If;

    commit transaction _transName

    return 0
END
$$;

COMMENT ON PROCEDURE pc.add_archived_file_entry_xref IS 'AddArchivedFileEntryXRef';
