--
-- Name: add_protein_reference(text, text, integer, integer, text, integer, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_protein_reference(IN _name text, IN _description text, IN _authorityid integer, IN _proteinid integer, IN _namedeschash text, IN _maxproteinnamelength integer DEFAULT 32, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds a new protein reference entry to pc.t_protein_names
**
**  Arguments:
**    _name                     Protein name
**    _description              Protein description
**    _authorityID              Authority ID
**    _proteinID                Protein ID (corresponding to pc.t_proteins)
**    _nameDescHash             Name/description hash
**    _maxProteinNameLength     Maximum protein name length (default is 32; allowed range is 25 to 125)
**
**  Returns:
**    _returnCode will have the reference ID of the protein reference added to T_Protein_Names
**    _returnCode will be '0' if an error
**
**  Auth:   kja
**  Date:   10/08/2004 kja - Initial version
**          11/28/2005 kja - Changed for revised database architecture
**          02/11/2011 mem - Now validating that protein name is 25 characters or less; also verifying it does not contain a space
**          04/29/2011 mem - Added parameter _maxProteinNameLength; default is 25
**          12/11/2012 mem - Removed transaction
**          01/10/2013 mem - Now validating that _maxProteinNameLength is between 25 and 125; changed _maxProteinNameLength to 32
**          08/20/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _referenceID int;
BEGIN
    _message := '';
    _returnCode := '';

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
    -- Verify that protein name does not contain a space and is not too long
    ---------------------------------------------------

    If _name LIKE '% %' Then
        _message := format('Protein name contains a space: %s', _name);
        RAISE WARNING '%', _message;

        _returnCode = '0'
        RETURN;
    End If;

    If char_length(_name) > _maxProteinNameLength Then
        _message := format('Protein name is too long; max length is %s characters: _name', _maxProteinNameLength, _name);
        RAISE WARNING '%', _message;

        _returnCode = '0'
        RETURN;
    End If;

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT reference_id
    INTO _referenceID
    FROM pc.t_protein_names
    WHERE reference_fingerprint = _nameDescHash::citext;

    If FOUND Then
        -- Already exists; return the reference ID
        _returnCode := _referenceID::text;
        RETURN;
    End If;

    INSERT INTO pc.t_protein_names (
        name,
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
    RETURNING reference_id
    INTO _referenceID;

    _returnCode := _referenceID::text;
END
$$;


ALTER PROCEDURE pc.add_protein_reference(IN _name text, IN _description text, IN _authorityid integer, IN _proteinid integer, IN _namedeschash text, IN _maxproteinnamelength integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_protein_reference(IN _name text, IN _description text, IN _authorityid integer, IN _proteinid integer, IN _namedeschash text, IN _maxproteinnamelength integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_protein_reference(IN _name text, IN _description text, IN _authorityid integer, IN _proteinid integer, IN _namedeschash text, IN _maxproteinnamelength integer, INOUT _message text, INOUT _returncode text) IS 'AddProteinReference';

