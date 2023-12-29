--
-- Name: update_protein_collection_counts(integer, integer, integer, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.update_protein_collection_counts(IN _collectionid integer, IN _numproteins integer, IN _numresidues integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the protein and residue counts tracked in pc.t_protein_collections for the given protein collection
**
**  Arguments:
**    _collectionID     Protein collection ID
**    _numProteins      Number of proteins
**    _numResidues      Number of residues
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   09/14/2015 mem - Initial release
**          08/22/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    If Not Exists (SELECT protein_collection_id FROM pc.t_protein_collections WHERE protein_collection_id = _collectionID) Then
        _message := format('Protein collection ID not found in pc.t_protein_collections: %s', Coalesce(_collectionID, 0));
        _returnCode := 'U5201';
    Else
        UPDATE pc.t_protein_collections
        SET num_proteins = _numProteins,
            num_residues = _numResidues
        WHERE protein_collection_id = _collectionID;

        _message := format('Counts updated for Protein collection ID %s', _collectionID);
    End If;

END
$$;


ALTER PROCEDURE pc.update_protein_collection_counts(IN _collectionid integer, IN _numproteins integer, IN _numresidues integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_protein_collection_counts(IN _collectionid integer, IN _numproteins integer, IN _numresidues integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.update_protein_collection_counts(IN _collectionid integer, IN _numproteins integer, IN _numresidues integer, INOUT _message text, INOUT _returncode text) IS 'UpdateProteinCollectionCounts';

