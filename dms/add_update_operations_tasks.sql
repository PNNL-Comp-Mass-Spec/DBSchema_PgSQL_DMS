--
-- Name: add_update_operations_tasks(integer, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_operations_tasks(INOUT _id integer, IN _tasktype text, IN _task text, IN _requester text, IN _requestedpersonnel text, IN _assignedpersonnel text, IN _description text, IN _comments text, IN _labname text, IN _status text, IN _priority text, IN _workpackage text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing operations task entry
**
**  Arguments:
**    _id                   Input/output: task_id in t_operations_tasks
**    _taskType             Task type
**    _task                 Task title, e.g. 'Freezer Clean Out'
**    _requester            Person requesting the task
**    _requestedPersonnel   Requested personnel for the task; typically in the form 'Zink, Erika M (D3P704)', but any text is allowed
**    _assignedPersonnel    Assigned personnel for the task; typically in the form 'Zink, Erika M (D3P704)', but any text is allowed
**    _description          Task description
**    _comments             Additional comments
**    _labName              Lab name, e.g. 'BSF 2222' or 'Undefined; corresponds to a row in t_lab_locations
**    _status               Status: 'New', 'In Progress', or 'Completed'
**    _priority             Priority: 'Normal' or 'High'
**    _workPackage          Work package
**    _mode                 Mode: 'add' or 'update'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user (unused by this procedure)
**
**  Auth:   grk
**  Date:   09/01/2012
**          11/19/2012 grk - Added work package and closed date
**          11/04/2013 grk - Added _hoursSpent
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/16/2022 mem - Rename parameters
**          05/10/2022 mem - Add parameters _taskType and _labName
**                         - Remove parameter _hoursSpent
**          05/16/2022 mem - Do not log data validation errors
**          11/18/2022 mem - Rename parameter to _task
**          01/14/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _closed timestamp := null;
    _taskTypeID Int;
    _labID Int;
    _logErrors boolean := false;
    _curStatus text := '';
    _curClosed timestamp := null;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _taskType           := Trim(Coalesce(_taskType, 'Generic'));
        _task               := Trim(Coalesce(_task, ''));
        _requester          := Trim(Coalesce(_requester, ''));
        _requestedPersonnel := Trim(Coalesce(_requestedPersonnel, ''));
        _assignedPersonnel  := Trim(Coalesce(_assignedPersonnel, ''));
        _description        := Trim(Coalesce(_description, ''));
        _comments           := Trim(Coalesce(_comments, ''));
        _labName            := Trim(Coalesce(_labName, 'Undefined'));
        _status             := Trim(Coalesce(_status, ''));
        _priority           := Trim(Coalesce(_priority, ''));
        _workPackage        := Trim(Coalesce(_workPackage, ''));
        _mode               := Trim(Lower(Coalesce(_mode, '')));

        If _taskType = '' Then
            RAISE EXCEPTION 'Task type must be specified';
        End If;

        If _requester = '' Then
            RAISE EXCEPTION 'Requester must be specified';
        End If;

        If _status = '' Then
            RAISE EXCEPTION 'Status must be specified';
        End If;

        If _priority = '' Then
            RAISE EXCEPTION 'Priority must be specified';
        End If;

        If _status::citext In ('Completed', 'Not Implemented') Then
            _closed := CURRENT_TIMESTAMP;
        End If;

        ---------------------------------------------------
        -- Resolve task type name to task type ID
        ---------------------------------------------------

        SELECT task_type_id
        INTO _taskTypeID
        FROM t_operations_task_type
        WHERE task_type_name = _taskType::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Unrecognized task type name: %', _taskType;
        End If;

        ---------------------------------------------------
        -- Resolve lab name to ID
        ---------------------------------------------------

        SELECT lab_id
        INTO _labID
        FROM t_lab_locations
        WHERE lab_name = _labName::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Unrecognized lab name: %', _labName;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            If _id Is Null Then
                RAISE EXCEPTION 'Cannot update: operations task ID cannot be null';
            End If;

            SELECT status, closed
            INTO _curStatus, _curClosed
            FROM t_operations_tasks
            WHERE task_id = _id;

            If Not FOUND Then
                RAISE EXCEPTION 'Cannot update: operations task entry ID % does not exist', _id;
            End If;

            If _curStatus::citext In ('Completed', 'Not Implemented') Then
                _closed := _curClosed;
            End If;

        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_operations_tasks (
                task_type_id,
                task,
                requester,
                requested_personnel,
                assigned_personnel,
                description,
                comments,
                lab_id,
                status,
                priority,
                work_package,
                closed
            ) VALUES (
                _taskTypeID,
                _task,
                _requester,
                _requestedPersonnel,
                _assignedPersonnel,
                _description,
                _comments,
                _labID,
                _status,
                _priority,
                _workPackage,
                _closed
            )
            RETURNING task_id
            INTO _id;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_operations_tasks
            SET task_type_id        = _taskTypeID,
                task                = _task,
                requester           = _requester,
                requested_personnel = _requestedPersonnel,
                assigned_personnel  = _assignedPersonnel,
                description         = _description,
                comments            = _comments,
                lab_id              = _labID,
                status              = _status,
                priority            = _priority,
                work_package        = _workPackage,
                closed              = _closed
            WHERE task_id = _id;

        End If;

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


ALTER PROCEDURE public.add_update_operations_tasks(INOUT _id integer, IN _tasktype text, IN _task text, IN _requester text, IN _requestedpersonnel text, IN _assignedpersonnel text, IN _description text, IN _comments text, IN _labname text, IN _status text, IN _priority text, IN _workpackage text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_operations_tasks(INOUT _id integer, IN _tasktype text, IN _task text, IN _requester text, IN _requestedpersonnel text, IN _assignedpersonnel text, IN _description text, IN _comments text, IN _labname text, IN _status text, IN _priority text, IN _workpackage text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_operations_tasks(INOUT _id integer, IN _tasktype text, IN _task text, IN _requester text, IN _requestedpersonnel text, IN _assignedpersonnel text, IN _description text, IN _comments text, IN _labname text, IN _status text, IN _priority text, IN _workpackage text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateOperationsTasks';

