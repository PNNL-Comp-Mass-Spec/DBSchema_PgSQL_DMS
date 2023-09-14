--
-- Name: add_update_run_interval(integer, text, text, text, text, text, boolean, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_run_interval(IN _id integer, IN _comment text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _showdebug boolean DEFAULT false, INOUT _invalidusage integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Edits existing item in t_run_interval
**      This procedure cannot be used to add rows to t_run_interval
**
**  Arguments:
**    _id               Interval ID (equal to the ID of the dataset directly before the interval)
**    _comment          Usage comment, e.g. 'UserOnsite[100%], Proposal[49361], PropUser[50082]'
**    _mode             The only supported mode is 'update'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user
**    _showDebug        When true, show debug statements
**    _invalidUsage     Output: 1 if the usage text in _comment cannot be parsed (or if the total percentage is not 100); Update_Run_Op_Log uses this to skip invalid entries
**
**  Auth:   grk
**  Date:   02/15/2012
**          02/15/2012 grk - Modified percentage parameters
**          03/03/2012 grk - Changed to embedded usage tags
**          03/07/2012 mem - Now populating Last_Affected and Entered_By
**          03/21/2012 grk - Modified to handle modified Parse_Usage_Text
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/28/2017 mem - Disable logging to T_Log_Entries when Parse_Usage_Text reports an error
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/02/2017 mem - _id is no longer an output variable
**                         - Add parameters _showDebug and _invalidUsage
**                         - Pass _id and _invalidUsage to Parse_Usage_Text
**          05/03/2019 mem - Update comments
**          02/15/2022 mem - Update error messages and rename variables
**          08/30/2023 mem - Ported to PostgreSQL
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _usageXML XML;
    _cleanedComment text;

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

        _id           := Coalesce(_id, -1);
        _mode         := Trim(Lower(Coalesce(_mode, '')));
        _callingUser  := Trim(Coalesce(_callingUser, ''));
        _showDebug    := Coalesce(_showDebug, false);
        _invalidUsage := 0;

        If Not _comment Is Null Then
            _comment := Trim(_comment);
        End If;

        If _callingUser = '' Then
            _callingUser := session_user;
        End If;

        If _id < 0 Then
            RAISE EXCEPTION 'Invalid ID: %', _id;
        End If;

        ---------------------------------------------------
        -- Validate usage and comment
        --
        -- Parse_Usage_Text looks for special usage tags in the comment and extracts that information, returning it as XML
        --
        -- If _cleanedComment is initially 'UserOnsite[100%], Proposal[49361], PropUser[50082] Extra info about the interval'
        -- after calling Parse_Usage_Text, _cleanedComment will be 'Extra info about the interval'
        -- and _usageXML will be <u UserOnsite="100" Proposal="49361" PropUser="50082" />
        --
        -- If _cleanedComment only has 'UserOnsite[100%], Proposal[49361], PropUser[50082]', _cleanedComment will be empty after the call to Parse_Usage_Text
        --
        -- Since _validateTotal is set to true, if the percentages do not add up to 100%, Parse_Usage_Text will raise an error (and _usageXML will be null)
        ---------------------------------------------------

        _cleanedComment := _comment;

        If _showDebug Then
            RAISE INFO '%', 'Calling Parse_Usage_Text';
        End If;

        CALL public.parse_usage_text (
                        _comment => _cleanedComment,        -- Input / Output
                        _usageXML => _usageXML,             -- Output
                        _message => _message,               -- Output
                        _returnCode => _returnCode,         -- Output
                        _seq => _id,                        -- Procedure parse_usage_text uses this in status messages and warnings
                        _showDebug => _showDebug,
                        _validateTotal => true,
                        _invalidUsage => _invalidUsage);    -- Output

        If _showDebug Then
            If _returnCode = '' Then
                RAISE INFO 'Parse_Usage_Text return code is an empty string';
            Else
                RAISE INFO 'Parse_Usage_Text return code: %', _returnCode;
            End If;
        End If;

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _message;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry
            --
            If Not Exists (SELECT dataset_id FROM t_run_interval WHERE dataset_id = _id) Then
                _message := format('Invalid ID: %s; cannot update', _id);
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        ---------------------------------------------------
        -- Add mode is not supported
        ---------------------------------------------------

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_run_interval
            SET comment       = _comment,     -- store _comment here, not _cleanedComment; note that _comment is allowed to be null
                usage         = _usageXML,
                last_affected = CURRENT_TIMESTAMP,
                entered_by    = _callingUser
            WHERE dataset_id = _id;

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


ALTER PROCEDURE public.add_update_run_interval(IN _id integer, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean, INOUT _invalidusage integer) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_run_interval(IN _id integer, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean, INOUT _invalidusage integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_run_interval(IN _id integer, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean, INOUT _invalidusage integer) IS 'AddUpdateRunInterval';

