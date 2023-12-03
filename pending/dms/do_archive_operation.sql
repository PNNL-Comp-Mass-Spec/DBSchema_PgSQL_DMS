--
CREATE OR REPLACE PROCEDURE public.do_archive_operation
(
    _datasetName text,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Perform archive operation defined by _mode
**      Used by the Archive Detail Report, e.g. https://dms2.pnl.gov/archive/show/QC_Mam_23_01_R01_22Nov23_Titus_WBEH-23-08-17
**
**  Arguments:
**    _datasetName      Dataset name
**    _mode             Mode: 'ArchiveReset' or 'update_req'
**    _message          Output message
**    _returnCode       Return code
**    _callingUser      Calling user username
**
**  Auth:   grk
**  Date:   10/06/2004
**          04/17/2006 grk - Added stuff for set archive update
**          03/27/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _result int;
    _datasetID int;
    _archiveStateID int;
    _newState int;
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

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetName := Trim(Coalesce(_datasetName, ''));
    _mode        := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Get datasetID and archive state
    ---------------------------------------------------

    SELECT t_dataset.dataset_id,
           t_dataset_archive.archive_state_id
    INTO _datasetID, _archiveStateID
    FROM t_dataset
         INNER JOIN t_dataset_archive
           ON t_dataset.dataset_id = t_dataset_archive.dataset_id
    WHERE dataset = _datasetName;

    If Not FOUND Then
        _msg := format('Could not get ID or archive state for dataset "%s"', _datasetName);
        RAISE EXCEPTION '%', _msg;

        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Reset state of failed archive dataset to 'new'
    ---------------------------------------------------

    If _mode = 'archivereset' Then

        -- If archive not in failed state, we can't reset it
        --
        If Not _archiveStateID In (6, 2) -- 'Operation Failed' or 'Archive In Progress' Then
            _msg := format('Archive state for dataset "%s" not in proper state to be reset', _datasetName);
            RAISE EXCEPTION '%', _msg;

            _message := 'message';
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;

        -- Reset the Archive task to state 'new'
        _newState := 1;

        -- Update archive state of dataset to new

        UPDATE t_dataset_archive
        SET archive_state_id = _newState
        WHERE (dataset_id  = _datasetID)

        -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
        If char_length(_callingUser) > 0 Then
            CALL public.alter_event_log_entry_user ('public', 6, _datasetID, _newState, _callingUser, _message => _alterEnteredByMessage);
        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Reset state of failed archive dataset to 'Update Required'
    ---------------------------------------------------

    If _mode = 'update_req' Then

        -- Change the Archive Update state to 'Update Required'
        _newState := 2;

        -- Update archive update state of dataset

        UPDATE t_dataset_archive
        SET archive_update_state_id = _newState
        WHERE (dataset_id  = _datasetID)

        -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
        If char_length(_callingUser) > 0 Then
            CALL public.alter_event_log_entry_user ('public', 7, _datasetID, _newState, _callingUser, _message => _alterEnteredByMessage);
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

COMMENT ON PROCEDURE public.do_archive_operation IS 'DoArchiveOperation';
