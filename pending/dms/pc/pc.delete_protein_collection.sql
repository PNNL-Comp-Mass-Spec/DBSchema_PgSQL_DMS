--
CREATE OR REPLACE PROCEDURE pc.delete_protein_collection
(
    _collectionID int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Deletes the given Protein Collection (use with caution)
**            Collection_State_ID must be 1 or 2
**
**  Auth:   mem
**  Date:   06/24/2008
**          02/23/2016 mem - Add Set XACT_ABORT on
**          06/20/2018 mem - Delete entries in T_Protein_Collection_Members_Cached
**                         - Add RAISERROR calls with severity level 11 (forcing the Catch block to be entered)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _collectionName text;
    _stateName text;
    _archivedFileID int;
    _callingProcName text;
    _currentLocation text;
    _logErrors int := 0;
    _collectionState int;
    _transName text;
    _logMessage text;
BEGIN
    Set XACT_ABORT, nocount on

    _message := '';
    _returnCode:= '';

    _currentLocation := 'Start';

    Begin Try

        _currentLocation := 'Examine _collectionState in pc.t_protein_collections'    ;

        ---------------------------------------------------
        -- Check if collection is OK to delete
        ---------------------------------------------------

        SELECT collection_state_id INTO _collectionState
        FROM pc.t_protein_collections
        WHERE protein_collection_id = _collectionID
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 0 Then
            _message := 'Collection_ID ' || _collectionID::text || ' not found in pc.t_protein_collections; unable to continue';
            RAISE INFO '%', _message;
            Return;
        End If;

        SELECT collection_name
        INTO _collectionName
        FROM pc.t_protein_collections
        WHERE (protein_collection_id = _collectionID)

        SELECT state INTO _stateName
        FROM pc.t_protein_collection_states
        WHERE (collection_state_id = _collectionState)

        If _collectionState > 2     Then
            _msg := 'Cannot Delete collection "' || _collectionName || '": ' || _stateName || ' collections are protected';
            RAISERROR (_msg, 10, 1)

            return 51140
        End If;

        _logErrors := 1;
        ---------------------------------------------------
        -- Start transaction
        ---------------------------------------------------

        _transName := 'DeleteProteinCollection';
        Begin transaction _transName

        ---------------------------------------------------
        -- Delete the collection members
        ---------------------------------------------------

        Call delete_protein_collection_members _collectionID, _message => _message output

        If _myError <> 0 Then
            rollback transaction _transName
            RAISERROR ('Protein collection members deletion was unsuccessful', 10, 1)
            return 51130
        End If;

        -- Look for this collection's archived_file_id in pc.t_archived_output_file_collections_xref
        _archivedFileID := -1;
        -- Moved to bottom of query: TOP 1
        SELECT archived_file_id INTO _archivedFileID
        FROM pc.t_archived_output_file_collections_xref
        WHERE protein_collection_id = _collectionID
        LIMIT 1;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -- Delete the entry from pc.t_archived_output_file_collections_xref
        DELETE FROM pc.t_archived_output_file_collections_xref
        WHERE protein_collection_id = _collectionID
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -- Delete the entry from pc.t_archived_output_files if not used in pc.t_archived_output_file_collections_xref
        If Not Exists (SELECT * FROM pc.t_archived_output_file_collections_xref where archived_file_id = _archivedFileID) Then
            DELETE FROM pc.t_archived_output_files
            WHERE (archived_file_id = _archivedFileID)
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        End If;

        -- Delete the entry from pc.t_annotation_groups
        DELETE FROM pc.t_annotation_groups
        WHERE (protein_collection_id = _collectionID)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        DELETE FROM pc.t_protein_collection_members_cached
        WHERE (protein_collection_id = _collectionID)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -- Delete the entry from pc.t_protein_collections
        DELETE FROM pc.t_protein_collections
        WHERE protein_collection_id = _collectionID
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        commit transaction _transname

    End Try
    Begin Catch
        Call format_error_message _message output, _myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0 Then
            ROLLBACK TRANSACTION;
        End If;

        If _logErrors > 0 Then
            _logMessage := format('%s; Protein Collection %s', _message, _CollectionID);
            Call post_log_entry ('Error', _logMessage, 'DeleteProteinCollection');
        End If;

        RAISE INFO '%', _message;
        If _myError <> 0 Then
            _myError := 50000;
        End If;

    End Catch

Done:
    return _myError

END
$$;

COMMENT ON PROCEDURE pc.delete_protein_collection IS 'DeleteProteinCollection';
