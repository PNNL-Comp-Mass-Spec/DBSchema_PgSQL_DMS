--
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
**  Desc:   Adds a new protein sequence entry to T_Proteins
**
**
**
**  Arguments:
**    _mode   The only option is "add"
**
**  Auth:   kja
**  Date:   10/06/2004
**          12/11/2012 mem - Removed transaction
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _proteinID int;
BEGIN
    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    _proteinID := 0;

    execute _proteinID = GetProteinID _length, _sha1Hash

    if _proteinID > 0 and _mode = 'add' Then
        return _proteinID
    End If;

    if _mode = 'add' Then
        ---------------------------------------------------
        -- action for add mode
        ---------------------------------------------------
        --
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
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            _msg := 'Insert operation failed!';
            RAISERROR (_msg, 10, 1)
            return 51007
        End If;
    End If;

    return _proteinID
END
$$;

COMMENT ON PROCEDURE pc.add_protein_sequence IS 'AddProteinSequence';
