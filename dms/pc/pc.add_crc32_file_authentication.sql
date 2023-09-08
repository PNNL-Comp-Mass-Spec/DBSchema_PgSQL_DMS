--
-- Name: add_crc32_file_authentication(integer, text, integer, integer, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_crc32_file_authentication(IN _collectionid integer, IN _crc32filehash text, IN _numproteins integer DEFAULT 0, IN _totalresiduecount integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds a CRC32 fingerprint to a given Protein Collection Entry in in pc.t_protein_collections
**
**      If both _numProteins and _totalResidueCount are non-zero, also updates num_proteins and num_residues
**
**  Arguments:
**    _collectionID         Protein collection ID
**    _crc32FileHash        CRC-32 file hash
**    _numProteins          The number of proteins for this protein collection
**    _totalResidueCount    The number of residues for this protein collection
**
**  Auth:   kja
**  Date:   04/15/2005
**          07/20/2015 mem - Added parameters _numProteins and _totalResidueCount
**          08/18/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _collectionID      := Coalesce(_collectionID, 0);
    _numProteins       := Coalesce(_numProteins, 0);
    _totalResidueCount := Coalesce(_totalResidueCount, 0);

    If Not Exists (SELECT protein_collection_id FROM pc.t_protein_collections WHERE protein_collection_id = _collectionID) Then
        _message := format('protein_collection_id %s not found in pc.t_protein_collections', Coalesce(_collectionID, 0));
        RAISE EXCEPTION '%', _message;
    End If;

    UPDATE pc.t_protein_collections
    SET authentication_hash = _crc32FileHash,
        date_modified = CURRENT_TIMESTAMP
    WHERE protein_collection_id = _collectionID;

    If _numProteins > 0 And _totalResidueCount > 0 Then
        UPDATE pc.t_protein_collections
        SET num_proteins = _numProteins,
            num_residues = _totalResidueCount
        WHERE protein_collection_id = _collectionID;
    End If;

END
$$;


ALTER PROCEDURE pc.add_crc32_file_authentication(IN _collectionid integer, IN _crc32filehash text, IN _numproteins integer, IN _totalresiduecount integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_crc32_file_authentication(IN _collectionid integer, IN _crc32filehash text, IN _numproteins integer, IN _totalresiduecount integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_crc32_file_authentication(IN _collectionid integer, IN _crc32filehash text, IN _numproteins integer, IN _totalresiduecount integer, INOUT _message text, INOUT _returncode text) IS 'AddCRC32FileAuthentication';

