--
-- Name: add_protein_sequence(text, integer, text, double precision, double precision, text, integer, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_protein_sequence(IN _sequence text, IN _length integer, IN _molecularformula text, IN _monoisotopicmass double precision, IN _averagemass double precision, IN _sha1hash text, IN _isencrypted integer, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add a new protein sequence entry to pc.t_proteins
**
**  Arguments:
**    _sequence             Protein sequence
**    _length               Protein sequence length
**    _molecularFormula     Empirical formula
**    _monoisotopicMass     Monoisotopic mass
**    _averageMass          Average mass
**    _sha1Hash             SHA-1 hash of the protein sequence
**    _isEncrypted          0 if not encrypted, 1 if encrypted
**    _mode                 The only supported mode is 'add'
**    _message              Status message
**    _returnCode           Return code
**
**  Returns:
**    If pc.t_proteins already has a protein with the given sequence length and SHA-1 hash, _returnCode will have the protein_id
**    Otherwise, _returnCode will have the protein_id of the row added to t_proteins
**
**  Auth:   kja
**  Date:   10/06/2004
**          12/11/2012 mem - Removed transaction
**          08/20/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _proteinID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT protein_id
    INTO _proteinID
    FROM pc.t_proteins
    WHERE length = _length AND sha1_hash = _sha1Hash::citext;

    If FOUND And _mode = 'add' Then
        _returnCode := _proteinID::text;
        RETURN;
    End If;

    If _mode = 'add' Then
        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        INSERT INTO pc.t_proteins (
            sequence,
            length,
            molecular_formula,
            monoisotopic_mass,
            average_mass,
            sha1_hash,
            is_encrypted,
            date_created,
            date_modified
        ) VALUES (
            _sequence,
            _length,
            _molecularFormula,
            _monoisotopicMass,
            _averageMass,
            _sha1Hash,
            _isEncrypted,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        )
        RETURNING protein_id
        INTO _proteinID;

        _returnCode := _proteinID::text;
    End If;

END
$$;


ALTER PROCEDURE pc.add_protein_sequence(IN _sequence text, IN _length integer, IN _molecularformula text, IN _monoisotopicmass double precision, IN _averagemass double precision, IN _sha1hash text, IN _isencrypted integer, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_protein_sequence(IN _sequence text, IN _length integer, IN _molecularformula text, IN _monoisotopicmass double precision, IN _averagemass double precision, IN _sha1hash text, IN _isencrypted integer, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_protein_sequence(IN _sequence text, IN _length integer, IN _molecularformula text, IN _monoisotopicmass double precision, IN _averagemass double precision, IN _sha1hash text, IN _isencrypted integer, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddProteinSequence';

