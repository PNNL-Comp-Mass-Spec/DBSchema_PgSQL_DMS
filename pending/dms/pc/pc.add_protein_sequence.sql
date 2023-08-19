
CREATE OR REPLACE PROCEDURE pc.add_protein_sequence
(
    _sequence text,
    _length int,
    _molecularFormula text,
    _monoisotopicMass float,
    _averageMass float,
    _sha1Hash text,
    _isEncrypted int,
    _mode text default 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a new protein sequence entry to T_Proteins
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
**
**  Returns:
**    If t_proteins already has a protein with the given sequence length and SHA-1 hash, _returnCode will have the protein_id
**    Otherwise, _returnCode will have the protein_id of the row added to t_proteins
**
**  Auth:   kja
**  Date:   10/06/2004
**          12/11/2012 mem - Removed transaction
**          12/15/2023 mem - Ported to PostgreSQL
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
            "sequence",
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

COMMENT ON PROCEDURE pc.add_protein_sequence IS 'AddProteinSequence';
