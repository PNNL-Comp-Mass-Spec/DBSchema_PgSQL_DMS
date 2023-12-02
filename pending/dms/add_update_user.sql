--
CREATE OR REPLACE PROCEDURE public.add_update_user
(
    _username text,
    _hanfordIdNum text,
    _lastNameFirstName text,
    _email text,
    _userStatus text,
    _userUpdate text,
    _operationsList text,
    _comment text = '',
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or updates an existing DMS user
**
**  Arguments:
**    _username             Network login for the user (was traditionally D+Payroll number, but switched to last name plus 3 digits around 2011)
**    _hanfordIdNum         Hanford ID number for user; cannot be blank
**    _lastNameFirstName    Cannot be blank (though this field is auto-updated by procedure update_users_from_warehouse)
**    _email                Can be blank; will be auto-updated by update_users_from_warehouse
**    _userStatus           Status: 'Active' or 'Inactive'; when 'Active', the user is active in DMS
**    _userUpdate           Update: 'Y' or 'N'; when 'Y', auto-update the user using update_users_from_warehouse()
**    _operationsList       Comma-separated list of access permissions (aka operation names); see table t_user_operations
**    _mode                 Mode: 'add' or 'update'
**    _message              Output message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   01/27/2004
**          11/03/2006 jds - Added support for U_Status field, removed _accessList varchar(256)
**          01/23/2008 grk - Added _userUpdate
**          10/14/2010 mem - Added _comment
**          06/01/2012 mem - Added Try/Catch block
**          06/05/2013 mem - Now calling Add_Update_User_Operations
**          06/11/2013 mem - Renamed the first two parameters (previously _username and _username)
**          02/23/2016 mem - Add Set XACT_ABORT on
**          08/23/2016 mem - Auto-add 'H' when _mode is 'add' and _hanfordIdNum starts with a number
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/11/2017 mem - Require _hanfordIdNum to be at least 2 characters long
**          08/01/2017 mem - Use THROW if not authorized
**          08/16/2018 mem - Remove any text before a backslash in _username (e.g., change from PNL\D3L243 to D3L243)
**          02/10/2022 mem - Remove obsolete payroll field
**                         - Always add 'H' to _hanfordIdNum if it starts with a number
**          03/16/2022 mem - Replace tab characters with spaces
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _charPos int := 0;
    _userID int := 0;
    _logMessage text;

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

        _username := Trim(Replace(_username, chr(9), ' '));
        _lastNameFirstName := Trim(Replace(_lastNameFirstName, chr(9), ' '));
        _hanfordIdNum := Trim(Replace(_hanfordIdNum, chr(9), ' '));
        _userStatus := Trim(_userStatus);

        If char_length(_username) < 1 Then
            _returnCode := 'U5201';
            RAISE EXCEPTION 'Username must be specified';
        Else
            _charPos := Position('\' In _username);

            If _charPos > 0 Then
                _username := Substring(_username, _charPos + 1, char_length(_username));
            End If;
        End If;

        If char_length(_lastNameFirstName) < 1 Then
            _returnCode := 'U5202';
            RAISE EXCEPTION 'Last Name, First Name must be specified';
        End If;
        --
        If char_length(_hanfordIdNum) <= 1 Then
            _returnCode := 'U5203';
            RAISE EXCEPTION 'Hanford ID number cannot be blank or a single character';
        End If;
        --
        If char_length(_userStatus) < 1 Then
            _returnCode := 'U5204';
            RAISE EXCEPTION 'User status must be specified';
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        _userID := public.get_user_id(_username);

        -- Cannot create an entry that already exists
        --
        If _userID <> 0 And _mode = 'add' Then
            RAISE EXCEPTION 'Cannot add: User "%" already in database ', _username;
        End If;

        -- Cannot update a non-existent entry
        --
        If _userID = 0 And _mode = 'update' Then
            RAISE EXCEPTION 'Cannot update: User "%" is not in database ', _username;
        End If;

        ---------------------------------------------------
        -- Add an H to _hanfordIdNum if it starts with a number
        ---------------------------------------------------

        If _hanfordIdNum SIMILAR TO '[0-9]%' Then
            _hanfordIdNum := format('H%s', _hanfordIdNum);
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            INSERT INTO t_users (
                username,
                name,
                hid,
                email,
                status,
                update,
                comment
            ) VALUES (
                _username,
                _lastNameFirstName,
                _hanfordIdNum,
                _email,
                _userStatus,
                _userUpdate,
                Coalesce(_comment, '')
            )
            RETURNING user_id
            INTO _userID;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then
            If _userStatus = 'Inactive' Then

                UPDATE t_users
                SET name = _lastNameFirstName,
                    hid = _hanfordIdNum,
                    email = _email,
                    status = _userStatus,
                    active = 'N',
                    update = 'N',
                    comment = _comment
                WHERE username = _username;

            Else

                UPDATE t_users
                SET
                    name = _lastNameFirstName,
                    hid = _hanfordIdNum,
                    email = _email,
                    status = _userStatus,
                    update = _userUpdate,
                    comment = _comment
                WHERE username = _username;

            End If;
        End If;

        ---------------------------------------------------
        -- Add/update operations defined for user
        ---------------------------------------------------

        CALL public.add_update_user_operations (
                        _userID,
                        _operationsList,
                        _message    => _message,        -- Output
                        _returnCode => _returnCode);    -- Output

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then

            _logMessage := format('%s; Username %s', _exceptionMessage, _username);

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
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

COMMENT ON PROCEDURE public.add_update_user IS 'AddUpdateUser';
