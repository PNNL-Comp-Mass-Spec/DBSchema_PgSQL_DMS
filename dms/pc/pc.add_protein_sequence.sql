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
**  Return value:
**    If pc.t_proteins already has a protein with the given sequence length and SHA-1 hash, _returnCode will have the protein_id
**    Otherwise, _returnCode will have the protein_id of the row added to t_proteins
**
**  Auth:   kja
**  Date:   10/06/2004
**          12/11/2012 mem - Removed transaction
**          08/20/2023 mem - Ported to PostgreSQL
**          07/26/2024 mem - Assure that _mode is lowercase
**          02/12/2025 mem - For existing proteins, update the molecular formula and monoisotopic if they differ from _molecularFormula or _monoisotopicMass
**
*****************************************************/
DECLARE
    _proteinID int;
    _currentMolecularFormula citext;
    _currentMonoisotopicMass float;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Assure that _mode is lowercase
    ---------------------------------------------------

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT protein_id, molecular_formula, monoisotopic_mass
    INTO _proteinID, _currentMolecularFormula, _currentMonoisotopicMass
    FROM pc.t_proteins
    WHERE length = _length AND sha1_hash = _sha1Hash::citext;

    If FOUND And _mode = 'add' Then

        If character_length(_molecularFormula) > 0 AND _currentMolecularFormula IS DISTINCT FROM _molecularFormula OR
           _monoisotopicMass > 0 AND Abs(_currentMonoisotopicMass - _monoisotopicMass) > 0.5 Then

           -- Update the molecular formula, monoisotopic mass, and average mass
           UPDATE pc.t_proteins
           SET molecular_formula = _molecularFormula,
               monoisotopic_mass = _monoisotopicMass,
               average_mass      = _averageMass,
               date_modified     = CURRENT_TIMESTAMP
           WHERE protein_id = _proteinID;

        End If;

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

