--
CREATE OR REPLACE PROCEDURE pc.add_update_protein_collection
(
    _collectionName text,
    _description text,
    _collectionSource text = '',
    _collectionType int = 1,
    _collectionState int,
    _primaryAnnotationTypeId int,
    _numProteins int = 0,
    _numResidues int = 0,
    _active int = 1,
    _mode text = 'add',
    INOUT _message text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Adds a new protein collection entry
**
**  Return values: The new Protein Collection ID if success; otherwise, 0
**
**  Arguments:
**    _collectionName   Protein collection name (not the original .fasta file name)
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
    _myRowCount int := 0;
    _collectionID Int := 0;
    _transName text;
BEGIN
    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    if char_length(_collectionName) < 1 Then
        _myError := 51000;
        _message := '_collectionName was blank';
        RAISERROR (_message, 10, 1)
    End If;

    -- Make sure _collectionName does not contain a space
    _collectionName := Trim(_collectionName);

    If _collectionName Like '% %' Then
        _myError := 51001;
        _message := 'Protein collection contains a space: "' || _collectionName || '"';
        RAISERROR (_message, 10, 1)
    End If;

    if _myError <> 0 Then
        -- Return zero, since we did not create a protein collection
        Return 0
    End If;

    -- Make sure the Source and Description do not have text surrounded by < and >, since web browsers will treat that as an HTML tag
    _collectionSource := REPLACE(REPLACE(Coalesce(_collectionSource, ''), '<', '('), '>', ')');
    _description := REPLACE(REPLACE(Coalesce(_description,      ''), '<', '('), '>', ')');

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    _collectionID := pc.get_protein_collection_id (_collectionName);

    if _collectionID > 0 and _mode = 'add' Then
        -- Collection already exists; change _mode to 'update'
        _mode := 'update';
    End If;

    if _collectionID = 0 and _mode = 'update' Then
        -- Collection not found; change _mode to 'add'
        _mode := 'add';
    End If;

    -- Uncomment to debug
    --
    -- set _message = 'mode ' || _mode || ', collection '|| _collectionName
    -- exec PostLogEntry 'Debug', _message, 'AddUpdateProteinCollection'
    -- set _message=''

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'AddProteinCollectionEntry';
    begin transaction _transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if _mode = 'add' Then

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
        )
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            rollback transaction _transName
            _message := 'Insert operation failed: "' || _collectionName || '"';
            RAISERROR (_message, 10, 1)
            -- Return zero, since we did not create a protein collection
            Return 0
        End If;

--            INSERT INTO pc.t_annotation_groups (
--            protein_collection_id,
--            annotation_group,
--            annotation_type_id
--            ) VALUES (
--            _collectionID,
--            0,
--            _primaryAnnotationTypeId
--            )

    End If;

    if _mode = 'update' Then

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
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            rollback transaction _transName
            _message := 'Update operation failed: "' || _collectionName || '"';
            RAISERROR (_message, 10, 1)
            -- Return zero, since we did not create a protein collection
            Return 0
        End If;
    End If;

    commit transaction _transName

    -- Lookup the collection ID for _collectionName
    _collectionID := pc.get_protein_collection_id (_collectionName);

    if _mode = 'add' Then
        _transName := 'AddProteinCollectionEntry';
        begin transaction _transName

        INSERT INTO pc.t_annotation_groups (
            protein_collection_id,
            annotation_group,
            annotation_type_id
        ) VALUES (
            _collectionID,
            0,
            _primaryAnnotationTypeId
        )
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            rollback transaction _transName
            _message := 'Update operation failed: "' || _collectionName || '"';
            RAISERROR (_message, 10, 1)
            -- Return zero, since we did not create a protein collection
            Return 0
        End If;

        commit transaction _transName
    End If;

    return _collectionID
END
$$;

COMMENT ON PROCEDURE pc.add_update_protein_collection IS 'AddUpdateProteinCollection';
