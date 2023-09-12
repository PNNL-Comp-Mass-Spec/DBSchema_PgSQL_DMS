--
-- Name: add_update_protein_collection(text, text, text, integer, integer, integer, integer, integer, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_update_protein_collection(IN _collectionname text, IN _description text, IN _collectionsource text DEFAULT ''::text, IN _collectiontype integer DEFAULT 1, IN _collectionstate integer DEFAULT 1, IN _primaryannotationtypeid integer DEFAULT 14, IN _numproteins integer DEFAULT 0, IN _numresidues integer DEFAULT 0, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds a new protein collection entry
**
**  Arguments:
**    _collectionName           Protein collection name (not the original .fasta file name)
**    _description              Protein collection description
**    _collectionSource         Protein collection source
**    _collectionType           Protein collection type
**    _collectionState          Protein collection state (integer)
**    _primaryAnnotationTypeId  Primary annotation ID
**    _numProteins              Number of proteins
**    _numResidues              Number of residues
**    _mode                     'add' or 'update'
**
**  Returns:
**    _returnCode will have the protein collection ID of the added or updated protein collection if no errors
**    _returnCode will be '0' if _collectionName is blank or contains a space
**
**  Auth:   kja
**  Date:   09/29/2004
**          11/23/2005 KJA
**          09/13/2007 mem - Now using GetProteinCollectionID instead of @@Identity to lookup the collection ID
**          01/18/2010 mem - Now validating that _proteinCollectionName does not contain a space
**                         - Now returns 0 if an error occurs; returns the protein collection ID if no errors
**          11/24/2015 mem - Added _collectionSource
**          06/26/2019 mem - Add comments and convert tabs to spaces
**          01/20/2020 mem - Replace < and > with ( and ) in the source and description
**          08/21/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**                         - Update warning messages
**          09/11/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _collectionID int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _collectionName   := Trim(Coalesce(_collectionName, ''));
    _description      := Trim(Coalesce(_description, ''));
    _collectionSource := Trim(Coalesce(_collectionSource, ''));

    _mode             := Trim(Lower(Coalesce(_mode, '')));

    If char_length(_collectionName) < 1 Then
        _message := '_collectionName must be specified';
        RAISE WARNING '%', _message;

        -- The Organism Database Handler expects this procedure to return '0' if there is an error
        _returnCode := '0'
        RETURN;
    End If;

    If Not _mode In ('add', 'update') Then
        _message := 'Invalid mode; should be "add" or "update"';
        RAISE WARNING '%', _message;

        -- The Organism Database Handler expects this procedure to return '0' if there is an error
        _returnCode := '0'
        RETURN;
    End If;

    -- Make sure _collectionName does not contain a space

    If _collectionName Like '% %' Then
        _message := format('Protein collection contains a space: "%s"', _collectionName);
        RAISE WARNING '%', _message;

        -- The Organism Database Handler expects this procedure to return '0' if there is an error
        _returnCode := '0'
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the Description and Source do not have text surrounded by < and >, since web browsers will treat that as an HTML tag
    ---------------------------------------------------

    _description      := Replace(Replace(Coalesce(_description,      ''), '<', '('), '>', ')');
    _collectionSource := Replace(Replace(Coalesce(_collectionSource, ''), '<', '('), '>', ')');

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    _collectionID := pc.get_protein_collection_id(_collectionName);

    If _collectionID > 0 And _mode = 'add' Then
        -- Collection already exists; auto-change _mode to 'update'
        _mode := 'update';
    End If;

    If _collectionID = 0 And _mode = 'update' Then
        -- Collection not found; auto-change _mode to 'add'
        _mode := 'add';
    End If;

    -- Uncomment to debug
    --
    -- _message := format('mode %s, collection %s', _mode, _collectionName);
    -- Call public.post_log_entry ('Debug', _message, 'Add_Update_Protein_Collection', 'pc');
    -- _message := ''

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        INSERT INTO pc.t_protein_collections (
            collection_name,
            description,
            source,
            collection_type_id,
            collection_state_id,
            primary_annotation_type_id,
            num_proteins,
            num_residues,
            date_created,
            date_modified,
            uploaded_by
        ) VALUES (
            _collectionName,
            _description,
            _collectionSource,
            _collectionType,
            _collectionState,
            _primaryAnnotationTypeId,
            _numProteins,
            _numResidues,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP,
            CURRENT_USER
        );

    End If;

    If _mode = 'update' Then

        UPDATE pc.t_protein_collections
        SET description = _description,
            source = CASE WHEN _collectionSource = '' AND Coalesce(source, '') <> '' THEN source ELSE _collectionSource END,
            collection_state_id = _collectionState,
            collection_type_id = _collectionType,
            num_proteins = _numProteins,
            num_residues = _numResidues,
            date_modified = CURRENT_TIMESTAMP
        WHERE collection_name = _collectionName;

    End If;

    -- Lookup the collection ID for _collectionName
    _collectionID := pc.get_protein_collection_id(_collectionName);

    If _mode = 'add' And _collectionID > 0 Then

        INSERT INTO pc.t_annotation_groups(
            protein_collection_id,
            annotation_group,
            annotation_type_id )
        VALUES(
            _collectionID,
            0,
            _primaryAnnotationTypeId
        );

    End If;

    _returnCode := _collectionID::text;
END
$$;


ALTER PROCEDURE pc.add_update_protein_collection(IN _collectionname text, IN _description text, IN _collectionsource text, IN _collectiontype integer, IN _collectionstate integer, IN _primaryannotationtypeid integer, IN _numproteins integer, IN _numresidues integer, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_protein_collection(IN _collectionname text, IN _description text, IN _collectionsource text, IN _collectiontype integer, IN _collectionstate integer, IN _primaryannotationtypeid integer, IN _numproteins integer, IN _numresidues integer, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_update_protein_collection(IN _collectionname text, IN _description text, IN _collectionsource text, IN _collectiontype integer, IN _collectionstate integer, IN _primaryannotationtypeid integer, IN _numproteins integer, IN _numresidues integer, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateProteinCollection';

