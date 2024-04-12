--
-- Name: do_archive_operation(text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.do_archive_operation(IN _datasetname text, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Perform archive operation defined by _mode
**        'ArchiveReset' resets the archive task to state 1 if it in state 2 or 6
**        'update_req' changes the archive update state to 'Update Required'
**
**      Used by the Archive Detail Report, e.g. https://dms2.pnl.gov/archive/show/QC_Mam_23_01_R01_22Nov23_Titus_WBEH-23-08-17
**
**  Arguments:
**    _datasetName      Dataset name
**    _mode             Mode: 'ArchiveReset' or 'update_req'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   10/06/2004
**          04/17/2006 grk - Added stuff for set archive update
**          03/27/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/03/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _result int;
    _datasetID int;
    _archiveStateID int;
    _newState int;
    _targetType int;
    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetName := Trim(Coalesce(_datasetName, ''));
    _mode        := Trim(Lower(Coalesce(_mode, '')));
    _callingUser := Trim(Coalesce(_callingUser, ''));

    ---------------------------------------------------
    -- Get dataset ID and archive state
    ---------------------------------------------------

    SELECT DS.dataset_id,
           DA.archive_state_id
    INTO _datasetID, _archiveStateID
    FROM t_dataset DS
         INNER JOIN t_dataset_archive DA
           ON DS.dataset_id = DA.dataset_id
    WHERE DS.dataset = _datasetName::citext;

    If Not FOUND Then
        If Not Exists (SELECT dataset_id FROM t_dataset WHERE DS.dataset = _datasetName::citext) Then
            _message := format('Dataset does not exist: %s', _datasetName);
        Else
            _message := format('Dataset exists but has not been archived: %s', _datasetName);
        End If;

        _returnCode := 'U5201';
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Reset state of failed archive dataset to 'new'
    ---------------------------------------------------

    If _mode = 'archivereset' Then

        -- If archive is not in failed state, we can't reset it
        -- Valid states are 2 (Archive In Progress) or 6 (Operation Failed)

        If Not _archiveStateID In (2, 6) Then
            _returnCode := 'U5202';
            _message := format('Archive state for dataset "%s" is not in an allowed state to be reset', _datasetName);
            RAISE EXCEPTION '%', _message;
        End If;

        -- Reset the Archive task to state 'new'

        _newState := 1;

        UPDATE t_dataset_archive
        SET archive_state_id = _newState
        WHERE dataset_id = _datasetID;

        -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log

        If _callingUser <> '' Then
            _targetType := 6;
            CALL public.alter_event_log_entry_user ('public', _targetType, _datasetID, _newState, _callingUser, _message => _alterEnteredByMessage);
        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Reset state of failed archive dataset to 'Update Required'
    ---------------------------------------------------

    If _mode = 'update_req' Then

        -- Change the Archive Update state to 'Update Required'

        _newState := 2;

        UPDATE t_dataset_archive
        SET archive_update_state_id = _newState
        WHERE dataset_id = _datasetID;

        -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log

        If Trim(Coalesce(_callingUser, '')) <> '' Then
            _targetType := 7;
            CALL public.alter_event_log_entry_user ('public', _targetType, _datasetID, _newState, _callingUser, _message => _alterEnteredByMessage);
        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Mode was unrecognized
    ---------------------------------------------------

    _message := format('Mode "%s" was unrecognized', _mode);
    RAISE WARNING '%', _message;

    _returnCode := 'U5203';

END
$$;


ALTER PROCEDURE public.do_archive_operation(IN _datasetname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE do_archive_operation(IN _datasetname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.do_archive_operation(IN _datasetname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DoArchiveOperation';

