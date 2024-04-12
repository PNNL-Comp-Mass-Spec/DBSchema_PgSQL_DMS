--
-- Name: add_collection_organism_xref(integer, integer, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_collection_organism_xref(IN _proteincollectionid integer, IN _organismid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add an entry to pc.t_collection_organism_xref
**
**  Arguments:
**    _proteinCollectionID  Protein collection ID
**    _organismID           Organism ID
**    _message              Status message
**    _returnCode           Return code
**
**  Returns:
**    If a row already exists matching _proteinCollectionID and _organismID, _returnCode will have the member_id of that row
**    Otherwise, _returnCode will have the member_id of the row added to pc.t_collection_organism_xref
**
**  Auth:   kja
**  Date:   06/01/2006
**          08/15/2006 mem - Updated to return _memberID if the mapping already exists, or 0 or a negative number if it doesn't
**          08/18/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _memberID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _proteinCollectionID := Coalesce(_proteinCollectionID, 0);
    _organismID          := Coalesce(_organismID, 0);

    If Not Exists (SELECT protein_collection_id FROM pc.t_protein_collections WHERE protein_collection_id = _proteinCollectionID) Then
        _message := format('Invalid protein collection ID; %s not found in pc.t_protein_collections', _proteinCollectionID);
        RAISE EXCEPTION '%', _message;
    End If;

    If Not Exists (SELECT organism_id FROM public.t_organisms WHERE organism_id = _organismID) Then
        _message := format('Invalid organism ID; %s not found in t_organisms', _organismID);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT id
    INTO _memberID
    FROM pc.t_collection_organism_xref
    WHERE protein_collection_id = _proteinCollectionID AND
          organism_id = _organismID;

    If FOUND Then
        _returnCode := _memberID::text;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    INSERT INTO pc.t_collection_organism_xref (protein_collection_id, organism_id)
    VALUES (_proteinCollectionID, _organismID)
    RETURNING ID
    INTO _memberID;

    _returnCode := _memberID::text;
END
$$;


ALTER PROCEDURE pc.add_collection_organism_xref(IN _proteincollectionid integer, IN _organismid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_collection_organism_xref(IN _proteincollectionid integer, IN _organismid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_collection_organism_xref(IN _proteincollectionid integer, IN _organismid integer, INOUT _message text, INOUT _returncode text) IS 'AddCollectionOrganismXRef';

