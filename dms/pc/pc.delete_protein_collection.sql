--
-- Name: delete_protein_collection(integer, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.delete_protein_collection(IN _collectionid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete the given protein collection, removing rows from the following tables:
**        pc.t_archived_output_file_collections_xref
**        pc.t_archived_output_files
**        pc.t_annotation_groups
**        pc.t_protein_collection_members_cached
**        pc.t_protein_collections
**
**      The protein collection must have state 1 or 2 (New or Provisional) in pc.t_protein_collections
**
**  Arguments:
**    _collectionID     Protein collection ID
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   06/24/2008
**          02/23/2016 mem - Add Set XACT_ABORT on
**          06/20/2018 mem - Delete entries in T_Protein_Collection_Members_Cached
**                         - Add RAISERROR calls with severity level 11 (forcing the Catch block to be entered)
**          08/21/2023 mem - Ported to PostgreSQL
**          07/26/2024 mem - Set _numProteinsForReload to 0 when calling delete_protein_collection_members
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
    _collectionStateID int;
    _logMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN
        _currentLocation := 'Examine collection_state_id in pc.t_protein_collections';

        RAISE INFO '';

        ---------------------------------------------------
        -- Check if collection is OK to delete
        ---------------------------------------------------

        _collectionID := Coalesce(_collectionID, 0);

        SELECT collection_state_id, collection_name
        INTO _collectionStateID, _collectionName
        FROM pc.t_protein_collections
        WHERE protein_collection_id = _collectionID;

        If Not FOUND Then
            _message := format('Protein collection ID %s not found in pc.t_protein_collections; unable to continue', _collectionID);
            RAISE WARNING '%', _message;

            _returnCode := 'U5102';
            RETURN;
        End If;

        SELECT state
        INTO _stateName
        FROM pc.t_protein_collection_states
        WHERE collection_state_id = _collectionStateID;

        If _collectionStateID > 2 Then
            _message := format('Cannot delete protein collection %s since it has state %s', _collectionName, _stateName);
            RAISE WARNING '%', _message;

            _returnCode := 'U5103';
            RETURN;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Delete the collection members
        ---------------------------------------------------

        CALL pc.delete_protein_collection_members (
                    _collectionID,
                    _numProteinsForReload => 0,
                    _message              => _message,      -- Output
                    _returnCode           => _returnCode);  -- Output

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
            _returnCode := 'U5104';
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
        If _archivedFileID > 0 And Not Exists (SELECT archived_file_id FROM pc.t_archived_output_file_collections_xref WHERE archived_file_id = _archivedFileID) Then
            DELETE FROM pc.t_archived_output_files
            WHERE archived_file_id = _archivedFileID;
        End If;

        -- Delete the entry from pc.t_annotation_groups
        DELETE FROM pc.t_annotation_groups
        WHERE protein_collection_id = _collectionID;

        DELETE FROM pc.t_protein_collection_members_cached
        WHERE protein_collection_id = _collectionID;

        -- Delete the entry from pc.t_protein_collections
        DELETE FROM pc.t_protein_collections
        WHERE protein_collection_id = _collectionID;

        RAISE INFO 'Deleted protein collection ID %', _collectionID;

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


ALTER PROCEDURE pc.delete_protein_collection(IN _collectionid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_protein_collection(IN _collectionid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.delete_protein_collection(IN _collectionid integer, INOUT _message text, INOUT _returncode text) IS 'DeleteProteinCollection';

