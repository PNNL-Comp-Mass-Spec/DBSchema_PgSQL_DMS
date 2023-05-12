--
-- Name: update_protein_sequence_info(integer, text, integer, text, double precision, double precision, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.update_protein_sequence_info(IN _proteinid integer, IN _sequence text, IN _length integer, IN _molecularformula text, IN _monoisotopicmass double precision, IN _averagemass double precision, IN _sha1hash text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update an existing protein
**
**  Auth:   kja
**  Date:   10/06/2004
**          05/01/2023 mem - Ported to PostgreSQL
**          05/11/2023 mem - Update return code
**
*****************************************************/
DECLARE
    _tmpHash text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT sha1_hash
    INTO _tmpHash
    FROM pc.t_proteins
    WHERE protein_id = _proteinID;

    If Not FOUND Then
        _message := format('Protein ID %s not found', _proteinID);
        RAISE WARNING '%', _message;
        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    UPDATE pc.t_proteins
    SET "sequence" = _sequence,
        length = _length,
        molecular_formula = _molecularFormula,
        monoisotopic_mass = _monoisotopicMass,
        average_mass = _averageMass,
        sha1_hash = _sha1Hash,
        date_modified = CURRENT_TIMESTAMP
    WHERE protein_id = _proteinID;

END
$$;


ALTER PROCEDURE pc.update_protein_sequence_info(IN _proteinid integer, IN _sequence text, IN _length integer, IN _molecularformula text, IN _monoisotopicmass double precision, IN _averagemass double precision, IN _sha1hash text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_protein_sequence_info(IN _proteinid integer, IN _sequence text, IN _length integer, IN _molecularformula text, IN _monoisotopicmass double precision, IN _averagemass double precision, IN _sha1hash text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.update_protein_sequence_info(IN _proteinid integer, IN _sequence text, IN _length integer, IN _molecularformula text, IN _monoisotopicmass double precision, IN _averagemass double precision, IN _sha1hash text, INOUT _message text, INOUT _returncode text) IS 'UpdateProteinSequenceInfo';

