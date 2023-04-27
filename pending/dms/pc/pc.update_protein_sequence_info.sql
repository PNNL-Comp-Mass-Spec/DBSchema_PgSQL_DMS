--
CREATE OR REPLACE PROCEDURE pc.update_protein_sequence_info
(
    _proteinID int,
    _sequence text,
    _length int,
    _molecularFormula text,
    _monoisotopicMass float,
    _averageMass float,
    _sha1Hash text,
    INOUT _message text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Adds a new protein sequence entry to T_Proteins
**
**
**
**  Auth:   kja
**  Date:   10/06/2004
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _tmpHash as text;
    _transName text;
BEGIN
    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT sha1_hash INTO _tmpHash
    FROM pc.t_proteins
    WHERE protein_id = _proteinID

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    if _myRowCount = 0 Then
        _msg := 'Protein ID ' || _proteinID || ' not found';
        RAISERROR(_msg, 10, 1)
        return  -50001
    End If;

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'UpdateProteinCollectionEntry';
    begin transaction _transName

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
/*        INSERT INTO pc.t_proteins (
            "sequence",
            length,
            molecular_formula,
            monoisotopic_mass,
            average_mass,
            sha1_hash,
            date_created,
            date_modified
        ) VALUES (
            _sequence,
            _length,
            _molecularFormula,
            _monoisotopicMass,
            _averageMass,
            _sha1Hash,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        )

    SELECT @@Identity          INTO _proteinID
*/

    UPDATE pc.t_proteins
    SET "sequence" = _sequence,
        length = _length,
        molecular_formula = _molecularFormula,
        monoisotopic_mass = _monoisotopicMass,
        average_mass = _averageMass,
        sha1_hash = _sha1Hash,
        date_modified = CURRENT_TIMESTAMP
    WHERE protein_id = _proteinID

        --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
    if _myError <> 0 Then
        rollback transaction _transName
        _msg := 'Update operation failed!';
        RAISERROR (_msg, 10, 1)
        return 51007
    End If;

    commit transaction _transName

    return 0
END
$$;

COMMENT ON PROCEDURE pc.update_protein_sequence_info IS 'UpdateProteinSequenceInfo';
