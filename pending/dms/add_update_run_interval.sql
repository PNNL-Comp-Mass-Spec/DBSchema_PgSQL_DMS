--
CREATE OR REPLACE PROCEDURE public.add_update_run_interval
(
    _id int,
    _comment text,
    _mode text = 'update',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = '',
    _showDebug boolean = false,
    INOUT _invalidUsage int = 0             -- Leave as an integer since called from the website
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Edits existing item in T_Run_Interval
**      This procedure cannot be used to add rows to T_Run_Interval
**
**  Arguments:
**    _comment        Usage comment, e.g. 'User[100%], Proposal[49521], PropUser[50151]'
**    _mode           'update' (note that 'add' is not supported)
**    _invalidUsage   Output: will be 1 if the usage text in _comment cannot be parsed (or if the total percentage is not 100); UpdateRunOpLog uses this to skip invalid entries
**
**  Auth:   grk
**  Date:   02/15/2012
**          02/15/2012 grk - modified percentage parameters
**          03/03/2012 grk - changed to embedded usage tags
**          03/07/2012 mem - Now populating Last_Affected and Entered_By
**          03/21/2012 grk - modified to handle modified ParseUsageText
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/28/2017 mem - Disable logging to T_Log_Entries when ParseUsageText reports an error
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/02/2017 mem - _id is no longer an output variable
**                         - Add parameters _showDebug and _invalidUsage
**                         - Pass _id and _invalidUsage to ParseUsageText
**          05/03/2019 mem - Update comments
**          02/15/2022 mem - Update error messages and rename variables
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _existingID int := 0;
    _logErrors boolean := false;
    _usageXML XML;
    _cleanedComment text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _id := Coalesce(_id, -1);
    _message := '';
    _returnCode:= '';
    _showDebug := Coalesce(_showDebug, false);
    _invalidUsage := 0;

    _callingUser := Coalesce(_callingUser, '');
    If _callingUser = '' Then
        _callingUser := session_user;
    End If;

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        If _id < 0 Then
            RAISE EXCEPTION 'Invalid ID: %', _id;
        End If;

        ---------------------------------------------------
        -- Validate usage and comment
        -- ParseUsageText looks for special usage tags in the comment and extracts that information, returning it as XML
        --
        -- If _comment is 'User[100%], Proposal[49361], PropUser[50082] Extra information about interval'
        -- after calling ParseUsageText, _cleanedComment will be 'Extra information about interval'
        -- and _usageXML will be <u User="100" Proposal="49361" PropUser="50082" />
        --
        -- If _comment only has 'User[100%], Proposal[49361], PropUser[50082]', _cleanedComment will be empty after the call to ParseUsageText
        --
        -- Since _validateTotal is set to 1, if the percentages do not add up to 100%, ParseUsageText will raise an error (and _usageXML will be null)
        ---------------------------------------------------

        _cleanedComment := _comment;

        If _showDebug Then
            RAISE INFO '%', 'Calling ParseUsageText';
        End If;

        Call parse_usage_text (_cleanedComment => _cleanedComment,      -- Input / Output
                               _usageXML => _usageXML,                  -- Output
                               _message => _message,                    -- Output
                               _returnCode => _returnCode,              -- Output
                               _seq => _ID,
                               _showDebug => _showDebug,
                               _validateTotal => true,
                               _invalidUsage => _invalidUsage);

        If _showDebug Then
            RAISE INFO 'ParseUsageText return code: %', _returnCode;
        End If;

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _message;
        End If;

        If _showDebug Then
            RAISE INFO '_returnCode is '''' after ParseUsageText';
        End If;

        _logErrors := true;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry
            --
            SELECT interval_id
            INTO _existingID
            FROM t_run_interval
            WHERE interval_id = _id;

            If Not FOUND Then
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
        --
        If _mode = 'update' Then

            UPDATE t_run_interval
            SET comment = _comment,
                usage = _usageXML,
                last_affected = CURRENT_TIMESTAMP,
                entered_by = _callingUser
            WHERE interval_id = _id
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

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

COMMENT ON PROCEDURE public.add_update_run_interval IS 'AddUpdateRunInterval';
