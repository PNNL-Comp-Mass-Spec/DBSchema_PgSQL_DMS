--
CREATE OR REPLACE PROCEDURE pc.update_file_archive_entry_collection_list
(
    _archivedFileEntryID int,
    _proteinCollectionList text,
    _sha1Hash text,
    _collectionListHexHash text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the protein collection list and hash values for the given archived output file
**
**  Auth:   kja
**  Date:   02/21/2007
**          02/11/2009 mem - Added parameter _collectionListHexHash
**                         - Now storing _sha1Hash in Authentication_Hash instead of in Collection_List_Hash
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    UPDATE pc.t_archived_output_files
    SET
        protein_collection_list   = _proteinCollectionList,
        authentication_hash       = _sha1Hash,
        collection_list_hex_hash  = _collectionListHexHash
    WHERE archived_file_id = _archivedFileEntryID;

END
$$;

COMMENT ON PROCEDURE pc.update_file_archive_entry_collection_list IS 'UpdateFileArchiveEntryCollectionList';
