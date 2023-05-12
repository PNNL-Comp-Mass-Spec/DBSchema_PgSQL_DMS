--
CREATE OR REPLACE PROCEDURE pc.add_archived_file_entry_xref
(
    _collectionID int,
    _archivedFileID int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds an Archived File Entry to T_Archived_Output_File_Collections_XRef
**      for a given Protein Collection ID
**
**  Arguments:
**    _collectionID         Protein collection ID
**    _archivedFileID       Archived file ID
**
**  Auth:   kja
**  Date:   03/17/2006 kja - Initial version
**          03/12/2014 mem - Now validating _collectionID and _archivedFileID
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode:= '';

    -------------------------------------------------
    -- Verify the File ID and Collection ID
    ---------------------------------------------------

    If Not Exists (SELECT * FROM pc.t_protein_collections WHERE protein_collection_id = _collectionID) Then
        _message := 'protein_collection_id ' || _collectionID::text || ' not found in pc.t_protein_collections';
        _returnCode := 'U5201';
        RETURN;
    End If;

    If Not Exists (SELECT * FROM pc.t_archived_output_files WHERE archived_file_id = _archivedFileID) Then
        _message := 'archived_file_id ' || _archivedFileID::text || ' not found in pc.t_archived_output_files';
        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    If Exists ( SELECT *
                FROM pc.t_archived_output_file_collections_xref
                WHERE archived_file_id = _archivedFileID AND
                      protein_collection_id = _collectionID)
    Then
        _message := 'Table t_archived_output_file_collections_xref already has a row with archived file ID %s and protein collection ID %s', _archivedFileID, _collectionID);
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    INSERT INTO pc.t_archived_output_file_collections_xref (archived_file_id, protein_collection_id)
    VALUES (_archivedFileID, _collectionID);

END
$$;

COMMENT ON PROCEDURE pc.add_archived_file_entry_xref IS 'AddArchivedFileEntryXRef';
