--
CREATE OR REPLACE PROCEDURE pc.update_protein_sequence_hash
(
    _proteinID int,
    _sha1Hash text,
    _seguid text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the SHA1 fingerprint for a given Protein Sequence Entry
**
**  Arguments:
**      _proteinID
**      _sha1Hash
**      _seguid     Unique sequence identifier (SEGUID) checksum (see https://www.nature.com/articles/npre.2007.278.1.pdf and https://pubmed.ncbi.nlm.nih.gov/16858731/)
**
**  Auth:   kja
**  Date:   03/13/2006
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _transName text;
BEGIN
    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'UpdateProteinSequenceHash';
    begin transaction _transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    begin

    UPDATE pc.t_proteins
    SET
        sha1_hash = _sha1Hash,
        seguid = _seguid
    WHERE (protein_id = _proteinID)

        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            rollback transaction _transName
            _msg := 'Update operation failed!';
            RAISERROR (_msg, 10, 1)
            return 51007
        End If;
    end

    commit transaction _transName

    return 0
END
$$;

COMMENT ON PROCEDURE pc.update_protein_sequence_hash IS 'UpdateProteinSequenceHash';
