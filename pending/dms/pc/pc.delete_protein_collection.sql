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
    _currentLocation text := 'Start';
    _msg text;
    _collectionName text;
    _stateName text;
    _archivedFileID int;
    _callingProcName text;
    _logErrors boolean := false;
    _collectionState int;
    _logMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN
        _currentLocation := 'Examine _collectionState in pc.t_protein_collections'    ;

        ---------------------------------------------------
        -- Check if collection is OK to delete
        ---------------------------------------------------

        SELECT collection_state_id
        INTO _collectionState
        FROM pc.t_protein_collections
        WHERE protein_collection_id = _collectionID

        If Not FOUND Then
            _message := format('Collection_ID %s not found in pc.t_protein_collections; unable to continue', _collectionID);
            RAISE WARNING '%', _message;

            _returnCode := 'U5102';
            RETURN;
        End If;

        SELECT collection_name
        INTO _collectionName
        FROM pc.t_protein_collections
        WHERE protein_collection_id = _collectionID;

        SELECT state INTO _stateName
        FROM pc.t_protein_collection_states
        WHERE collection_state_id = _collectionState;

        If _collectionState > 2     Then
            _message := 'Cannot Delete collection "%s" since it has state %s', _collectionName, _stateName);
            RAISE WARNING '%', _message;

            _returnCode := 'U5102';
            RETURN;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Delete the collection members
        ---------------------------------------------------

        CALL delete_protein_collection_members (_collectionID, _message => _message, _returnCode => _returnCode);

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    If _returnCode <> '' Then
        ROLLBACK;

        _msg := 'Protein collection members deletion was unsuccessful';

        If Coalesce(_message, '') = '' Then
            _message := _msg;
        Else
            _message := format('%s: %s', _msg, _message);
        End If;

        RAISE WARNING '%', _message;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := 'U5103';
        End If;

        RETURN;
    End If;

    BEGIN
        -- Look for this collection's archived_file_id in pc.t_archived_output_file_collections_xref

        SELECT archived_file_id
        INTO _archivedFileID
        FROM pc.t_archived_output_file_collections_xref
        WHERE protein_collection_id = _collectionID
        LIMIT 1;

        If Not Found Then
            _archivedFileID := 0;
        End If;

        -- Delete the entry from pc.t_archived_output_file_collections_xref
        DELETE FROM pc.t_archived_output_file_collections_xref
        WHERE protein_collection_id = _collectionID;

        -- Delete the entry from pc.t_archived_output_files if not used in pc.t_archived_output_file_collections_xref
        If _archivedFileID > 0 And Not Exists (SELECT * FROM pc.t_archived_output_file_collections_xref WHERE archived_file_id = _archivedFileID) Then
            DELETE FROM pc.t_archived_output_files
            WHERE archived_file_id = _archivedFileID
        End If;

        -- Delete the entry from pc.t_annotation_groups
        DELETE FROM pc.t_annotation_groups
        WHERE protein_collection_id = _collectionID;

        DELETE FROM pc.t_protein_collection_members_cached
        WHERE protein_collection_id = _collectionID;

        -- Delete the entry from pc.t_protein_collections
        DELETE FROM pc.t_protein_collections
        WHERE protein_collection_id = _collectionID;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

END
$$;

COMMENT ON PROCEDURE pc.delete_protein_collection IS 'DeleteProteinCollection';
