--
-- Name: add_update_user(text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_user(IN _username text, IN _hanfordid text, IN _lastnamefirstname text, IN _email text, IN _userstatus text, IN _userupdate text, IN _operationslist text, IN _comment text DEFAULT ''::text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or update an existing DMS user
**
**  Arguments:
**    _username             Network login for the user (was traditionally D+Payroll number, but switched to last name plus 3 digits around 2011)
**    _hanfordID            Hanford ID number for user; cannot be blank
**    _lastNameFirstName    Cannot be blank (though this field is auto-updated by procedure update_users_from_warehouse)
**    _email                Can be blank; will be auto-updated by update_users_from_warehouse
**    _userStatus           Status: 'Active' or 'Inactive'; when 'Active', the user is active in DMS
**    _userUpdate           Update: 'Y' or 'N'; when 'Y', auto-update the user using update_users_from_warehouse()
**    _operationsList       Comma-separated list of access permissions (aka operation names); see table t_user_operations
**    _mode                 Mode: 'add' or 'update'
**    _message              Status message
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
**          08/23/2016 mem - Auto-add 'H' when _mode is 'add' and _hanfordID starts with a number
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/11/2017 mem - Require _hanfordID to be at least 2 characters long
**          08/01/2017 mem - Use THROW if not authorized
**          08/16/2018 mem - Remove any text before a backslash in _username (e.g., change from PNL\D3L243 to D3L243)
**          02/10/2022 mem - Remove obsolete payroll field
**                         - Always add 'H' to _hanfordID if it starts with a number
**          03/16/2022 mem - Replace tab characters with spaces
**          01/21/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          05/22/2024 mem - Rename the Hanford ID parameter to _hanfordID
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**          08/14/2024 mem - Fix bug validating _userUpdate
**          07/19/2025 mem - Raise an exception if _mode is undefined or unsupported
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

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
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
        -- Replace tab characters with a space (which will be trimmed if it is at the beginning or end of the string)
        ---------------------------------------------------

        _username          := Trim(Replace(Coalesce(_username, ''),          chr(9), ' '));
        _hanfordID         := Trim(Replace(Coalesce(_hanfordID, ''),         chr(9), ' '));
        _lastNameFirstName := Trim(Replace(Coalesce(_lastNameFirstName, ''), chr(9), ' '));
        _email             := Trim(Replace(Coalesce(_email, ''),             chr(9), ' '));
        _userStatus        := Trim(Coalesce(_userStatus, ''));
        _userUpdate        := Trim(Coalesce(_userUpdate, ''));
        _operationsList    := Trim(Coalesce(_operationsList, ''));
        _comment           := Trim(Coalesce(_comment, ''));
        _mode              := Trim(Lower(Coalesce(_mode, '')));

        If _mode = '' Then
            RAISE EXCEPTION 'Empty string specified for parameter _mode';
        ElsIf Not _mode IN ('add', 'update', 'check_add', 'check_update') Then
            RAISE EXCEPTION 'Unsupported value for parameter _mode: %', _mode;
        End If;

        If _username = '' Then
            RAISE EXCEPTION 'Username must be specified' USING ERRCODE = 'U5201';
        Else
            _charPos := Position('\' In _username);

            If _charPos > 0 Then
                _username := Substring(_username, _charPos + 1, char_length(_username));
            End If;
        End If;

        If _lastNameFirstName = '' Then
            RAISE EXCEPTION 'Last Name, First Name must be specified' USING ERRCODE = 'U5202';
        End If;

        If char_length(_hanfordID) <= 1 Then
            RAISE EXCEPTION 'Hanford ID number cannot be blank or a single character' USING ERRCODE = 'U5203';
        End If;

        If _userStatus = '' Then
            RAISE EXCEPTION 'User status must be specified' USING ERRCODE = 'U5204';
        End If;

        If _userStatus::citext = 'Active' Then
            _userStatus := 'Active';
        ElsIf _userStatus::citext = 'Inactive' Then
            _userStatus := 'Inactive';
        ElsIf _userStatus::citext = 'Obsolete' Then
            _userStatus := 'Obsolete';
        Else
            RAISE EXCEPTION 'User status should be Active, Inactive, or Obsolete' USING ERRCODE = 'U5205';
        End If;

        If _userUpdate::citext In ('Y', 'Yes', '') Then
            _userUpdate := 'Y';
        ElsIf _userUpdate::citext In ('N', 'No') Then
            _userUpdate := 'N';
        Else
            RAISE EXCEPTION 'User update should be Y or N' USING ERRCODE = 'U5206';
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        _userID := public.get_user_id(_username);

        -- Cannot create an entry that already exists

        If _userID <> 0 And _mode = 'add' Then
            RAISE EXCEPTION 'Cannot add: user "%" already exists', _username USING ERRCODE = 'U5207';
        End If;

        -- Cannot update a non-existent entry

        If _userID = 0 And _mode = 'update' Then
            RAISE EXCEPTION 'Cannot update: user "%" does not exist', _username USING ERRCODE = 'U5208';
        End If;

        ---------------------------------------------------
        -- Add an H to _hanfordID if it starts with a number
        ---------------------------------------------------

        If _hanfordID SIMILAR TO '[0-9]%' Then
            _hanfordID := format('H%s', _hanfordID);
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
                _hanfordID,
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
            If _userStatus::citext = 'Inactive' Then

                UPDATE t_users
                SET name    = _lastNameFirstName,
                    hid     = _hanfordID,
                    email   = _email,
                    status  = _userStatus,
                    active  = 'N',
                    update  = 'N',
                    comment = _comment
                WHERE username = _username::citext;

            Else

                UPDATE t_users
                SET name    = _lastNameFirstName,
                    hid     = _hanfordID,
                    email   = _email,
                    status  = _userStatus,
                    update  = _userUpdate,
                    comment = _comment
                WHERE username = _username::citext;

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


ALTER PROCEDURE public.add_update_user(IN _username text, IN _hanfordid text, IN _lastnamefirstname text, IN _email text, IN _userstatus text, IN _userupdate text, IN _operationslist text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_user(IN _username text, IN _hanfordid text, IN _lastnamefirstname text, IN _email text, IN _userstatus text, IN _userupdate text, IN _operationslist text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_user(IN _username text, IN _hanfordid text, IN _lastnamefirstname text, IN _email text, IN _userstatus text, IN _userupdate text, IN _operationslist text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateUser';

