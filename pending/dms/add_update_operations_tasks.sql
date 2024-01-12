--
CREATE OR REPLACE PROCEDURE public.add_update_operations_tasks
(
    INOUT _id int,
    _taskType text,
    _task text,
    _requester text,
    _requestedPersonnel text,
    _assignedPersonnel text,
    _description text,
    _comments text,
    _labName text,
    _status text,
    _priority text,
    _workPackage text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing operation task entry
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
**    _callingUser          Username of the calling user
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
**          12/15/2024 mem - Ported to PostgreSQL
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

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _taskType := Trim(Coalesce(_taskType, 'Generic'));
        _labName  := Trim(Coalesce(_labName, 'Undefined'));
        _mode     := Trim(Lower(Coalesce(_mode, '')));

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
        WHERE lab_name = _labName;

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

            SELECT status,
                   closed
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
            SET task_type_id = _taskTypeID,
                task = _task,
                requester = _requester,
                requested_personnel = _requestedPersonnel,
                assigned_personnel = _assignedPersonnel,
                description = _description,
                comments = _comments,
                lab_id = _labID,
                status = _status,
                priority = _priority,
                work_package = _workPackage,
                closed = _closed
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

COMMENT ON PROCEDURE public.add_update_operations_tasks IS 'AddUpdateOperationsTasks';
