--
-- Name: add_update_protein_collection_member(integer, integer, integer, integer, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_update_protein_collection_member(IN _referenceid integer, IN _proteinid integer, IN _proteincollectionid integer, IN _sortingindex integer, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add or update a protein collection member, updating table pc.t_protein_collection_members
**
**  Arguments:
**    _referenceID          Protein reference ID, corresponding to a row in pc.t_protein_names
**    _proteinID            Protein ID,           corresponding to a row in pc.t_proteins
**    _proteinCollectionID  Protein collection ID
**    _sortingIndex         Sorting index
**    _mode                 Mode: 'add' to add a new collection member, 'update' to udpate the sorting index of an existing collection member
**    _message              Status message
**    _returnCode           Return code
**
**  Returns:
**    If _mode is 'add',    _returnCode will be the member_id of the row added to t_protein_collection_members
**    If _mode is 'update', _returnCode will be an empty string
**
**  Auth:   kja
**  Date:   10/06/2004
**          11/23/2005 kja - Added parameters
**          12/11/2012 mem - Removed transaction
**          08/21/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _memberID int;
BEGIN
    _message := '';
    _returnCode := '';

    If _mode = 'add' Then
        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        INSERT INTO pc.t_protein_collection_members (
            original_reference_id,
            protein_id,
            protein_collection_id,
            sorting_index
        ) VALUES (
            _referenceID,
            _proteinID,
            _proteinCollectionID,
            _sortingIndex
        )
        RETURNING member_id
        INTO _memberID;

        _returnCode := _memberID::text;

    End If;

    If _mode = 'update' Then
        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        UPDATE pc.t_protein_collection_members
        SET sorting_index = _sortingIndex
        WHERE protein_id = _proteinID AND
              original_reference_id = _referenceID AND
              protein_collection_id = _proteinCollectionID;
    End If;

END
$$;


ALTER PROCEDURE pc.add_update_protein_collection_member(IN _referenceid integer, IN _proteinid integer, IN _proteincollectionid integer, IN _sortingindex integer, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_protein_collection_member(IN _referenceid integer, IN _proteinid integer, IN _proteincollectionid integer, IN _sortingindex integer, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_update_protein_collection_member(IN _referenceid integer, IN _proteinid integer, IN _proteincollectionid integer, IN _sortingindex integer, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateProteinCollectionMember_New';

