--
-- Name: add_archived_file_entry_xref(integer, integer, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_archived_file_entry_xref(IN _collectionid integer, IN _archivedfileid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add an archived file entry to pc.t_archived_output_file_collections_xref for a given protein collection ID
**
**  Arguments:
**    _collectionID     Protein collection ID
**    _archivedFileID   Archived file ID
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   kja
**  Date:   03/17/2006 kja - Initial version
**          03/12/2014 mem - Now validating _collectionID and _archivedFileID
**          08/18/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    -------------------------------------------------
    -- Verify the File ID and Collection ID
    ---------------------------------------------------

    If Not Exists (SELECT protein_collection_id FROM pc.t_protein_collections WHERE protein_collection_id = _collectionID) Then
        _message := format('protein_collection_id %s not found in pc.t_protein_collections', Coalesce(_collectionID, 0));
        RAISE EXCEPTION '%', _message;
    End If;

    If Not Exists (SELECT archived_file_id FROM pc.t_archived_output_files WHERE archived_file_id = _archivedFileID) Then
        _message := format('archived_file_id %s not found in pc.t_archived_output_files', Coalesce(_archivedFileID, 0));
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    If Exists (SELECT entry_id
               FROM pc.t_archived_output_file_collections_xref
               WHERE archived_file_id = _archivedFileID AND
                     protein_collection_id = _collectionID)
    Then
        _message := format('Table pc.t_archived_output_file_collections_xref already has a row with archived file ID %s and protein collection ID %s',
                           _archivedFileID, _collectionID);
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    INSERT INTO pc.t_archived_output_file_collections_xref (archived_file_id, protein_collection_id)
    VALUES (_archivedFileID, _collectionID);

END
$$;


ALTER PROCEDURE pc.add_archived_file_entry_xref(IN _collectionid integer, IN _archivedfileid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_archived_file_entry_xref(IN _collectionid integer, IN _archivedfileid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_archived_file_entry_xref(IN _collectionid integer, IN _archivedfileid integer, INOUT _message text, INOUT _returncode text) IS 'AddArchivedFileEntryXRef';

