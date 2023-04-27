--
CREATE OR REPLACE PROCEDURE pc.update_file_archive_entry_collection_list
(
    _archivedFileEntryID int,
    _proteinCollectionList text,
    _sHA1Hash text,
    INOUT _message text,
    _collectionListHexHash text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Updates the SHA1 fingerprint for a given Protein Description Entry
**
**
**
**  Auth:   kja
**  Date:   02/21/2007
**          02/11/2009 mem - Added parameter _collectionListHexHash
**                         - Now storing _sha1Hash in Authentication_Hash instead of in Collection_List_Hash
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _transName text;
BEGIN
    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'UpdateFileArchiveEntryCollectionList';
    begin transaction _transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    begin

    UPDATE pc.t_archived_output_files
    SET
        protein_collection_list = _proteinCollectionList,
        authentication_hash =     _sHA1Hash,
        collection_list_hex_hash  = _collectionListHexHash
    WHERE (archived_file_id = _archivedFileEntryID)

        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            rollback transaction _transName
            _msg := 'Update operation failed!';
            RAISERROR (_msg, 10, 1)
            return 51007
        End If;
    end

    commit transaction _transName

    return 0
END
$$;

COMMENT ON PROCEDURE pc.update_file_archive_entry_collection_list IS 'UpdateFileArchiveEntryCollectionList';
