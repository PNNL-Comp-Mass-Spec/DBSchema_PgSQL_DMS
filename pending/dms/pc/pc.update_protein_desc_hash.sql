--
CREATE OR REPLACE PROCEDURE pc.update_protein_desc_hash
(
    _descriptionID int,
    _sha1Hash text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Updates the SHA1 fingerprint for a given Protein Description Entry
**
**
**
**  Auth:   kja
**  Date:   02/21/2007
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

    _transName := 'UpdateProteinDescHash';
    begin transaction _transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    begin

    UPDATE pc.t_protein_descriptions
    SET
        fingerprint = _sha1Hash
    WHERE (description_id = _descriptionID)

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

COMMENT ON PROCEDURE pc.update_protein_desc_hash IS 'UpdateProteinDescHash';
