--
CREATE OR REPLACE PROCEDURE pc.add_protein_reference
(
    _name text,
    _description text,
    _authorityID int,
    _proteinID int,
    _nameDescHash text,
    INOUT _message text,
    _maxProteinNameLength int = 32
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Adds a new protein reference entry to T_Protein_Names
**
**  Return values: The Reference ID for the protein name if success; otherwise, 0
**
**
**
**  Auth:   kja
**  Date:   10/08/2004 kja - Initial version
**          11/28/2005 kja - Changed for revised database architecture
**          02/11/2011 mem - Now validating that protein name is 25 characters or less; also verifying it does not contain a space
**          04/29/2011 mem - Added parameter _maxProteinNameLength; default is 25
**          12/11/2012 mem - Removed transaction
**          01/10/2013 mem - Now validating that _maxProteinNameLength is between 25 and 125; changed _maxProteinNameLength to 32
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _referenceID int;
BEGIN
    _message := '';

    If Coalesce(_maxProteinNameLength, 0) <= 0 Then
        _maxProteinNameLength := 32;
    End If;

    If _maxProteinNameLength < 25 Then
        _maxProteinNameLength := 25;
    End If;

    If _maxProteinNameLength > 125 Then
        _maxProteinNameLength := 125;
    End If;

    ---------------------------------------------------
    -- Verify name does not contain a space and is not too long
    ---------------------------------------------------

    If _name LIKE '% %' Then
        _myError := 51000;
        _message := 'Protein name contains a space: "' || _name || '"';
        RAISERROR (_message, 10, 1)
    End If;

    If char_length(_name) > _maxProteinNameLength Then
        _myError := 51001;
        _message := 'Protein name is too long; max length is ' || _maxProteinNameLength::text || ' characters: "' || _name || '"';
        RAISERROR (_message, 10, 1)
    End If;

    if _myError <> 0 Then
        -- Return zero, since we did not add the protein
        Return 0
    End If;

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    _referenceID := 0;

    execute _referenceID = GetProteinReferenceID _name, _nameDescHash

    if _referenceID > 0 Then
        -- Yes, already exists
        -- Return the reference ID
        return _referenceID
    End If;

    INSERT INTO pc.t_protein_names (
        "name",
        description,
        annotation_type_id,
        reference_fingerprint,
        date_added, protein_id
    ) VALUES (
        _name,
        _description,
        _authorityID,
        _nameDescHash,
        CURRENT_TIMESTAMP,
        _proteinID
    )
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    if _myError <> 0 Then
        _msg := 'Insert operation failed!';
        RAISERROR (_msg, 10, 1)
        return 51007
    End If;

    return _referenceID
END
$$;

COMMENT ON PROCEDURE pc.add_protein_reference IS 'AddProteinReference';
