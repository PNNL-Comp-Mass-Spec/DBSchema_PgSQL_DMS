--
-- Name: update_file_archive_entry_collection_list(integer, text, text, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.update_file_archive_entry_collection_list(IN _archivedfileentryid integer, IN _proteincollectionlist text, IN _crc32authentication text, IN _collectionlisthexhash text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the protein collection list and hash values in pc.t_archived_output_files for the given archived output file
**
**  Arguments:
**    _archivedFileEntryID      Archive output file ID
**    _proteinCollectionList    Protein collection list (comma-separated list of protein collection names)
**    _crc32Authentication      CRC32 authentication hash (hash of the bytes in the file)
**    _collectionListHexHash    SHA-1 hash of the protein collection list and creation options (separated by a forward slash)
**                              For example, 'H_sapiens_UniProt_SPROT_2023-03-01,Tryp_Pig_Bov/seq_direction=forward,filetype=fasta' has SHA-1 hash '11822db6bbfc1cb23c0a728a0b53c3b9d97db1f5'
**
**  Auth:   kja
**  Date:   02/21/2007
**          02/11/2009 mem - Added parameter _collectionListHexHash
**                         - Now storing _sha1Hash in Authentication_Hash instead of in Collection_List_Hash
**          08/22/2023 mem - Rename argument _sha1Hash to _crc32Authentication
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    UPDATE pc.t_archived_output_files
    SET protein_collection_list   = _proteinCollectionList,
        authentication_hash       = _crc32Authentication,
        collection_list_hex_hash  = _collectionListHexHash
    WHERE archived_file_id = _archivedFileEntryID;

END
$$;


ALTER PROCEDURE pc.update_file_archive_entry_collection_list(IN _archivedfileentryid integer, IN _proteincollectionlist text, IN _crc32authentication text, IN _collectionlisthexhash text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_file_archive_entry_collection_list(IN _archivedfileentryid integer, IN _proteincollectionlist text, IN _crc32authentication text, IN _collectionlisthexhash text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.update_file_archive_entry_collection_list(IN _archivedfileentryid integer, IN _proteincollectionlist text, IN _crc32authentication text, IN _collectionlisthexhash text, INOUT _message text, INOUT _returncode text) IS 'UpdateFileArchiveEntryCollectionList';

