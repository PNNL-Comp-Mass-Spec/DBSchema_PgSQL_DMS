--
-- Name: add_update_capture_scripts(text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.add_update_capture_scripts(IN _script text, IN _description text, IN _enabled text, IN _resultstag text, IN _contents text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit existing scripts in cap.t_scripts
**
**  Arguments:
**    _script           Capture task script name
**    _description      Script description
**    _enabled          Script enabled flag: 'Y' or 'N'
**    _resultsTag       Three letter abbreviation for the script
**    _contents         Script contents (XML as text)
**    _mode             'add' or 'update'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   09/23/2008 grk - Initial version
**          03/24/2009 mem - Now calling Alter_Entered_By_User when _callingUser is defined
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/04/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Raise a warning if an invalid operation
**          12/09/2022 mem - Change _mode to lowercase
**          04/27/2023 mem - Use boolean for data type name
**          05/12/2023 mem - Rename variables
**          05/23/2023 mem - Use format() for string concatenation
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          06/21/2023 mem - Assure that _enabled is uppercase
**          09/07/2023 mem - Update warning messages
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/03/2024 mem - Update warning messages
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          01/11/2024 mem - Check for an empty script name
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - Remove CR and LF from _contents
**                         - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _scriptId int;
    _scriptXML xml;
    _existingCount int;
    _alterEnteredByMessage text;

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

        _script      := Trim(Coalesce(_script, ''));
        _description := Trim(Coalesce(_description, ''));
        _enabled     := Trim(Upper(Coalesce(_enabled, 'Y')));
        _mode        := Trim(Lower(Coalesce(_mode, '')));
        _callingUser := Trim(Coalesce(_callingUser, ''));

        If _script = '' Then
            _message := 'Script name must be specified';
            _returnCode := 'U5201';
            RETURN;
        End If;

        If _description = '' Then
            _message := 'Description must be specified';
            _returnCode := 'U5202';
            RETURN;
        End If;

        If _mode <> 'add' and _mode <> 'update' Then
            _message := format('Unknown Mode: %s', _mode);
            _returnCode := 'U5203';
            RETURN;
        End If;

        If _contents Is Null Then
            _scriptXML := null;
        Else
            -- The website adds CR and LF to the end of each line; remove those (and any adjacent spaces)
            _contents := regexp_replace(_contents, ' *(' || chr(10) || '|' || chr(13) || ') *', '', 'g');

            _scriptXML := public.try_cast(_contents, null::xml);

            If _scriptXML Is Null Then
                _message := format('Script contents is not valid XML: %s', _contents);
                _returnCode := 'U5204';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        SELECT script_id
        INTO _scriptId
        FROM cap.t_scripts
        WHERE script = _script::citext;
        --
        GET DIAGNOSTICS _existingCount = ROW_COUNT;

        -- Cannot update a non-existent entry

        If _mode = 'update' And _existingCount = 0 Then
            _message := format('Cannot update: script "%s" does not exist', _script);
            RAISE WARNING '%', _message;
            _returnCode := 'U5205';
            RETURN;
        End If;

        -- Cannot add an existing entry

        If _mode = 'add' And _existingCount > 0 Then
            _message := format('Cannot add: script "%s" already exists', _script);
            RAISE WARNING '%', _message;
            _returnCode := 'U5206';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO cap.t_scripts (
                script,
                description,
                enabled,
                results_tag,
                contents
            ) VALUES (
                _script,
                _description,
                _enabled,
                _resultsTag,
                _scriptXML
            );

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE cap.t_scripts
            SET description = _description,
                enabled = _enabled,
                results_tag = _resultsTag,
                contents = _scriptXML
            WHERE script = _script;

        End If; -- update mode

        -- If _callingUser is defined, update entered_by in cap.t_scripts_history
        -- If _mode is 'update', a new row is only added to t_scripts_history if results_tag or contents changes for the script
        If Trim(Coalesce(_callingUser, '')) <> '' Then

            SELECT script_id
            INTO _scriptId
            FROM cap.t_scripts
            WHERE script = _script;

            If FOUND Then
                -- When calling alter_entered_by_user, we must associate the _message argument with a local variable, otherwise the following error occurs:
                -- 'procedure parameter "_message" is an output parameter but corresponding argument is not writable, state 42601'

                CALL public.alter_entered_by_user ('cap', 't_scripts_history', 'script_id', _scriptId, _callingUser, _message => _alterEnteredByMessage);

                RAISE INFO '%', _alterEnteredByMessage;
            End If;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE cap.add_update_capture_scripts(IN _script text, IN _description text, IN _enabled text, IN _resultstag text, IN _contents text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_capture_scripts(IN _script text, IN _description text, IN _enabled text, IN _resultstag text, IN _contents text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.add_update_capture_scripts(IN _script text, IN _description text, IN _enabled text, IN _resultstag text, IN _contents text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateScripts';

