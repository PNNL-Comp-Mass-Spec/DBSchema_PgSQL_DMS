--
CREATE OR REPLACE PROCEDURE pc.add_update_protein_collection
(
    _collectionName text,
    _description text,
    _collectionSource text default '',
    _collectionType int default 1,
    _collectionState int,
    _primaryAnnotationTypeId int,
    _numProteins int default 0,
    _numResidues int default 0,
    _mode text default 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _collectionID int
BEGIN
    _message := '';
    _returnCode := '';
    _collectionID := 0;

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If char_length(_collectionName) < 1 Then
        _message := '_collectionName was blank';
        RAISE WARNING '%', _message;

        -- The Organism Database Handler expects this procedure to return '0' if there is an error
        _returnCode := '0'
        RETURN;
    End If;

    -- Make sure _collectionName does not contain a space
    _collectionName := Trim(_collectionName);

    If _collectionName Like '% %' Then
        _message := format('Protein collection contains a space: "%s"', _collectionName);
        RAISE WARNING '%', _message;

        -- The Organism Database Handler expects this procedure to return '0' if there is an error
        _returnCode := '0'
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the Source and Description do not have text surrounded by < and >, since web browsers will treat that as an HTML tag
    ---------------------------------------------------

    _collectionSource := REPLACE(REPLACE(Coalesce(_collectionSource, ''), '<', '('), '>', ')');

    _description :=      REPLACE(REPLACE(Coalesce(_description,      ''), '<', '('), '>', ')');

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    _collectionID := pc.get_protein_collection_id (_collectionName);

    if _collectionID > 0 And _mode = 'add' Then
        -- Collection already exists; change _mode to 'update'
        _mode := 'update';
    End If;

    if _collectionID = 0 And _mode = 'update' Then
        -- Collection not found; change _mode to 'add'
        _mode := 'add';
    End If;

    -- Uncomment to debug
    --
    -- _message := 'mode ' || _mode || ', collection '|| _collectionName
    -- Call Post_Log_Entry ('Debug', _message, 'Add_Update_Protein_Collection');
    -- _message := ''

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
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
            SYSTEM_USER
        );

    End If;

    If _mode = 'update' Then

        UPDATE pc.t_protein_collections
        SET
            description = _description,
            source = Case When _collectionSource = '' and Coalesce(source, '') <> '' Then source Else _collectionSource End,
            collection_state_id = _collectionState,
            collection_type_id = _collectionType,
            num_proteins = _numProteins,
            num_residues = _numResidues,
            date_modified = CURRENT_TIMESTAMP
        WHERE collection_name = _collectionName;

    End If;

    -- Lookup the collection ID for _collectionName
    _collectionID := pc.get_protein_collection_id (_collectionName);

    If _mode = 'add' And _collectionID > 0 Then

        INSERT INTO pc.t_annotation_groups (
            protein_collection_id,
            annotation_group,
            annotation_type_id
        ) VALUES (
            _collectionID,
            0,
            _primaryAnnotationTypeId
        )

    End If;

    _returnCode := _collectionID::text;
END
$$;

COMMENT ON PROCEDURE pc.add_update_protein_collection IS 'AddUpdateProteinCollection';
