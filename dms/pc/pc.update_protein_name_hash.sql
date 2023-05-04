--
-- Name: update_protein_name_hash(integer, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.update_protein_name_hash(IN _referenceid integer, IN _sha1hash text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Updates the SHA-1 fingerprint in t_protein_names for the given Protein Reference Entry
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

    UPDATE pc.t_protein_names
    SET reference_fingerprint = _sha1Hash
    WHERE reference_id = _referenceID;

END
$$;


ALTER PROCEDURE pc.update_protein_name_hash(IN _referenceid integer, IN _sha1hash text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_protein_name_hash(IN _referenceid integer, IN _sha1hash text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.update_protein_name_hash(IN _referenceid integer, IN _sha1hash text, INOUT _message text, INOUT _returncode text) IS 'UpdateProteinNameHash';

