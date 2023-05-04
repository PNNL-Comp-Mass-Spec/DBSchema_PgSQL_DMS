--
-- Name: update_protein_sequence_hash(integer, text, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.update_protein_sequence_hash(IN _proteinid integer, IN _sha1hash text, IN _seguid text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the SHA-1 fingerprint in t_proteins for the given protein
**
**  Arguments:
**      _proteinID  Protein ID
**      _sha1Hash   SHA-1 Hash
**      _seguid     Unique sequence identifier (SEGUID) checksum (see https://www.nature.com/articles/npre.2007.278.1.pdf and https://pubmed.ncbi.nlm.nih.gov/16858731/)
**
**  Auth:   kja
**  Date:   03/13/2006
**          05/02/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    UPDATE pc.t_proteins
    SET
        sha1_hash = _sha1Hash,
        seguid = _seguid
    WHERE protein_id = _proteinID;

END
$$;


ALTER PROCEDURE pc.update_protein_sequence_hash(IN _proteinid integer, IN _sha1hash text, IN _seguid text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_protein_sequence_hash(IN _proteinid integer, IN _sha1hash text, IN _seguid text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.update_protein_sequence_hash(IN _proteinid integer, IN _sha1hash text, IN _seguid text, INOUT _message text, INOUT _returncode text) IS 'UpdateProteinSequenceHash';

