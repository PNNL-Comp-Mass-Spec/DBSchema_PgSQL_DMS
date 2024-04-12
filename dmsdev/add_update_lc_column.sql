--
-- Name: add_update_lc_column(text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_lc_column(INOUT _columnname text, IN _packingmfg text, IN _packingtype text, IN _particlesize text, IN _particletype text, IN _columninnerdia text, IN _columnouterdia text, IN _length text, IN _state text, IN _operatorusername text, IN _comment text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing LC column
**
**  Arguments:
**    _columnName        Input/output: Column name
**    _packingMfg        Column packing manufacturer
**    _packingType       Packing type
**    _particleSize      Particle size
**    _particleType      Particle type
**    _columnInnerDia    Column inner diameter
**    _columnOuterDia    Column outer diameter
**    _length            Column length
**    _state             State: 'New', 'Active', or 'Retired'
**    _operatorUsername  Username of the DMS user to associate with the column
**    _comment           Comment
**    _mode              Mode: 'add' or 'update'
**    _message           Status message
**    _returnCode        Return code
**
**  Auth:   grk
**  Date:   12/09/2003
**          08/19/2010 grk - Use try-catch for error handling
**          02/23/2016 mem - Add Set XACT_ABORT on
**          07/20/2016 mem - Fix error message entity name
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/19/2017 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/30/2018 mem - Make _columnName an output parameter
**          03/21/2022 mem - Fix typo in comment and update capitalization of keywords
**          01/14/2024 mem - Rename argument to _columnName
**                         - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _existingCount int;
    _columnID int;
    _stateID int;

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

        _columnName       := Trim(Coalesce(_columnName, ''));
        _packingMfg       := Trim(Coalesce(_packingMfg, ''));
        _packingType      := Trim(Coalesce(_packingType, ''));
        _particleSize     := Trim(Coalesce(_particleSize, ''));
        _particleType     := Trim(Coalesce(_particleType, ''));
        _columnInnerDia   := Trim(Coalesce(_columnInnerDia, ''));
        _columnOuterDia   := Trim(Coalesce(_columnOuterDia, ''));
        _length           := Trim(Coalesce(_length, ''));
        _state            := Trim(Coalesce(_state, ''));
        _operatorUsername := Trim(Coalesce(_operatorUsername, ''));
        _comment          := Trim(Coalesce(_comment, ''));
        _mode             := Trim(Lower(Coalesce(_mode, '')));

        If _columnName = '' Then
            _returnCode := 'U5110';
            RAISE EXCEPTION 'Column name must be specified';
        End If;

        If _state = '' Then
            _returnCode := 'U5111';
            RAISE EXCEPTION 'State name must be specified';
        End If;

        If _operatorUsername = '' Then
            _returnCode := 'U5112';
            RAISE EXCEPTION 'Operator username must be specified';
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        SELECT lc_column_id
        INTO _columnID
        FROM t_lc_column
        WHERE lc_column = _columnName::citext;
        --
        GET DIAGNOSTICS _existingCount = ROW_COUNT;

        -- Cannot create an entry that already exists

        If _existingCount > 0 And _mode = 'add' Then
            RAISE EXCEPTION 'Cannot add: LC column "%" already exists', _columnName;
        End If;

        -- Cannot update a non-existent entry

        If _existingCount = 0 And _mode = 'update' Then
            RAISE EXCEPTION 'Cannot update: LC column "%" does not exist', _columnName;
        End If;

        ---------------------------------------------------
        -- Resolve ID for state
        ---------------------------------------------------

        SELECT column_state_id
        INTO _stateID
        FROM t_lc_column_state_name
        WHERE column_state = _state::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid column state: %', _state;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            INSERT INTO t_lc_column (
                lc_column,
                packing_mfg,
                packing_type,
                particle_size,
                particle_type,
                column_inner_dia,
                column_outer_dia,
                column_length,
                column_state_id,
                operator_username,
                comment,
                created
            ) VALUES (
                _columnName,
                _packingMfg,
                _packingType,
                _particleSize,
                _particleType,
                _columnInnerDia,
                _columnOuterDia,
                _length,
                _stateID,
                _operatorUsername,
                _comment,
                CURRENT_TIMESTAMP
            );
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_lc_column
            SET lc_column         = _columnName,
                packing_mfg       = _packingMfg,
                packing_type      = _packingType,
                particle_size     = _particleSize,
                particle_type     = _particleType,
                column_inner_dia  = _columnInnerDia,
                column_outer_dia  = _columnOuterDia,
                column_length     = _length,
                column_state_id   = _stateID,
                operator_username = _operatorUsername,
                comment           = _comment
            WHERE lc_column_id = _columnID;

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


ALTER PROCEDURE public.add_update_lc_column(INOUT _columnname text, IN _packingmfg text, IN _packingtype text, IN _particlesize text, IN _particletype text, IN _columninnerdia text, IN _columnouterdia text, IN _length text, IN _state text, IN _operatorusername text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_lc_column(INOUT _columnname text, IN _packingmfg text, IN _packingtype text, IN _particlesize text, IN _particletype text, IN _columninnerdia text, IN _columnouterdia text, IN _length text, IN _state text, IN _operatorusername text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_lc_column(INOUT _columnname text, IN _packingmfg text, IN _packingtype text, IN _particlesize text, IN _particletype text, IN _columninnerdia text, IN _columnouterdia text, IN _length text, IN _state text, IN _operatorusername text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateLCColumn';

