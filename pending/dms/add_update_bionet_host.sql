--
CREATE OR REPLACE PROCEDURE public.add_update_bionet_host
(
    _host text,
    _ip text,
    _alias text,
    _tag text,
    _instruments text,
    _active int,
    _comment text,
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
**      Adds new or edits existing item in T_Bionet_Hosts
**
**  Date:   09/08/2016 mem - Initial version
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/03/2018 mem - Add _comment
**                         - Use _logErrors to toggle logging errors caught by the try/catch block
**          12/15/2023 mem - Ported to PostgreSQL
**
**  Arguments:
**    _mode   'add' or 'update'
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _logErrors boolean := false;

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

        If _mode IS NULL OR char_length(_mode) < 1 Then
            _returnCode := 'U5102';
            RAISE EXCEPTION '_mode must be specified';
        End If;

        If _host IS NULL OR char_length(_host) < 1 Then
            _returnCode := 'U5103';
            RAISE EXCEPTION '_host must be specified';
        End If;

        _ip := Coalesce(_ip, '');

        If char_length(Trim(Coalesce(_alias, ''))) = 0 Then
            _alias := null;
        End If;

        If char_length(Trim(Coalesce(_tag, ''))) = 0 Then
            _tag := null;
        End If;

        If char_length(Trim(Coalesce(_instruments, ''))) = 0 Then
            _instruments := null;
        End If;

        If char_length(Trim(Coalesce(_comment, ''))) = 0 Then
            _comment := null;
        End If;

        _active := Coalesce(_active, 1);

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode = 'add' And Exists (SELECT * FROM t_bionet_hosts WHERE host = _host) Then
            -- Cannot create an entry that already exists
            --
            _msg := format('Cannot add: item "%s" is already in the database', _host);
            RAISE EXCEPTION '%', _msg;
        End If;

        If _mode = 'update' And Not Exists (SELECT * FROM t_bionet_hosts WHERE host = _host) Then
            -- Cannot update a non-existent entry
            _msg := format('Cannot update: item "%s" is not in the database', _host);
            RAISE EXCEPTION '%', _msg;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_bionet_hosts(
                host,
                ip,
                alias,
                entered,
                instruments,
                active,
                tag,
                comment
            )
            VALUES (
                _host,
                _ip,
                _alias,
                CURRENT_TIMESTAMP,
                _instruments,
                _active,
                _tag,
                _comment
            );

        End If; -- add mode

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_bionet_hosts
            SET ip = _ip,
                alias = _alias,
                instruments = _instruments,
                active = _active,
                tag = _tag,
                comment = _comment
            WHERE host = _host;

        End If; -- update mode

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

COMMENT ON PROCEDURE public.add_update_bionet_host IS 'AddUpdateBionetHost';
