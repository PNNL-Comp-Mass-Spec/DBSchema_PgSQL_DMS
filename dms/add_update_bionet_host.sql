--
-- Name: add_update_bionet_host(text, text, text, text, text, integer, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_bionet_host(IN _host text, IN _ip text, IN _alias text, IN _tag text, IN _instruments text, IN _active integer, IN _comment text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing bionet host
**
**  Arguments:
**    _host             Host name
**    _ip               Host IP
**    _alias            Alias; empty string or null if not applicable
**    _tag              Computer property number, e.g. 'WE25477'; empty string or null if undefined
**    _instruments      Comma-separated list of instrument names
**    _active           1 if active, 0 if inactive
**    _comment          Comment
**    _mode             Mode: 'add' or 'update'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user (unused)
**
**  Date:   09/08/2016 mem - Initial version
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/03/2018 mem - Add _comment
**                         - Use _logErrors to toggle logging errors caught by the try/catch block
**          12/31/2023 mem - Ported to PostgreSQL
**          01/03/2024 mem - Update warning message
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _host        := Trim(Coalesce(_host, ''));
        _ip          := Trim(Coalesce(_ip, ''));
        _alias       := Trim(Coalesce(_alias, ''));
        _tag         := Trim(Coalesce(_tag, ''));
        _instruments := Trim(Coalesce(_instruments, ''));
        _active      := Coalesce(_active, 1);
        _comment     := Trim(Coalesce(_comment, ''));
        _mode        := Trim(Lower(Coalesce(_mode, '')));

        If _mode = '' Then
            _returnCode := 'U5102';
            RAISE EXCEPTION 'Mode must be specified';
        End If;

        If _host = '' Then
            _returnCode := 'U5103';
            RAISE EXCEPTION 'Host must be specified';
        End If;

        If _alias = '' Then
            _alias := null;
        End If;

        If _tag = '' Then
            _tag := null;
        End If;

        If _instruments = '' Then
            _instruments := null;
        End If;

        If _comment = '' Then
            _comment := null;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode = 'add' And Exists (SELECT host FROM t_bionet_hosts WHERE host = _host::citext) Then
            -- Cannot create an entry that already exists
            _msg := format('Cannot add: host "%s" already exists', _host);
            RAISE EXCEPTION '%', _msg;
        End If;

        If _mode = 'update' And Not Exists (SELECT host FROM t_bionet_hosts WHERE host = _host::citext) Then
            -- Cannot update a non-existent entry
            _msg := format('Cannot update: host "%s" does not exist', _host);
            RAISE EXCEPTION '%', _msg;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_bionet_hosts (
                host,
                ip,
                alias,
                entered,
                instruments,
                active,
                tag,
                comment
            ) VALUES (
                _host,
                _ip,
                _alias,
                CURRENT_TIMESTAMP,
                _instruments,
                _active,
                _tag,
                _comment
            );

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_bionet_hosts
            SET host        = _host,
                ip          = _ip,
                alias       = _alias,
                instruments = _instruments,
                active      = _active,
                tag         = _tag,
                comment     = _comment
            WHERE host = _host::citext;

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


ALTER PROCEDURE public.add_update_bionet_host(IN _host text, IN _ip text, IN _alias text, IN _tag text, IN _instruments text, IN _active integer, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_bionet_host(IN _host text, IN _ip text, IN _alias text, IN _tag text, IN _instruments text, IN _active integer, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_bionet_host(IN _host text, IN _ip text, IN _alias text, IN _tag text, IN _instruments text, IN _active integer, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateBionetHost';

