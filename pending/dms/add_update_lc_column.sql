--
CREATE OR REPLACE PROCEDURE public.add_update_lc_column
(
    INOUT _columnNumber text,
    _packingMfg text,
    _packingType text,
    _particleSize text,
    _particleType text,
    _columnInnerDia text,
    _columnOuterDia text,
    _length text,
    _state  text,
    _operatorUsername text,
    _comment text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a new entry to LC Column table
**
**  Arguments:
**    _columnNumber   Input/output: Aka column name
**    _mode           'add' or 'update'
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
**          11/30/2018 mem - Make _columnNumber an output parameter
**          03/21/2022 mem - Fix typo in comment and update capitalization of keywords
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := true;
    _existingCount int;
    _columnID int := -1;
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
        -- Validate input fields
        ---------------------------------------------------

        If char_length(Coalesce(_columnNumber, '')) < 1 Then
            _returnCode := 'U5110';
            RAISE EXCEPTION 'Column name was blank';
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        --
        SELECT lc_column_id
        INTO _columnID
        FROM t_lc_column
        WHERE (lc_column = _columnNumber)
        --
        GET DIAGNOSTICS _existingCount = ROW_COUNT;

        -- Cannot create an entry that already exists
        --
        If _existingCount > 0 And _mode = 'add' Then
            _logErrors := false;
            RAISE EXCEPTION 'Cannot add: Specified LC column already in database';
        End If;

        -- Cannot update a non-existent entry
        --
        If _existingCount = 0 And _mode = 'update' Then
            _logErrors := false;
            RAISE EXCEPTION 'Cannot update: Specified LC column is not in database';
        End If;

        ---------------------------------------------------
        -- Resolve ID for state
        ---------------------------------------------------

        --
        SELECT column_state_id
        INTO _stateID
        FROM t_lc_column_state_name
        WHERE column_state = _state

        If Not FOUND Then
            _logErrors := false;
            RAISE EXCEPTION 'Invalid column state: %', _state;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            INSERT INTO t_lc_column
            (
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
                _columnNumber,
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
            Set
                lc_column = _columnNumber,
                packing_mfg = _packingMfg,
                packing_type = _packingType,
                particle_size = _particleSize,
                particle_type = _particleType,
                column_inner_dia = _columnInnerDia,
                column_outer_dia = _columnOuterDia,
                column_length = _length,
                column_state_id = _stateID,
                operator_username = _operatorUsername,
                comment = _comment
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

COMMENT ON PROCEDURE public.add_update_lc_column IS 'AddUpdateLCColumn';
