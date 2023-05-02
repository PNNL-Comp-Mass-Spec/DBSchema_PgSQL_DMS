--
CREATE OR REPLACE PROCEDURE public.add_update_prep_lc_column
(
    _columnName text,
    _mfgName text,
    _mfgModel text,
    _mfgSerialNumber text,
    _packingMfg text,
    _packingType text,
    _particlesize text,
    _particletype text,
    _columnInnerDia text,
    _columnOuterDia text,
    _length text,
    _state text,
    _operatorUsername text,
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
**      Adds new or edits existing item in T_Prep_LC_Column
**
**  Arguments:
**    _mode   'add' or 'update'
**
**  Auth:   grk
**  Date:   07/29/2009 grk - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          04/11/2022 mem - Check for whitespace in _columnName
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _tmp int := 0;
BEGIN
    _message := '';
    _returnCode:= '';

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

    _columnName := Coalesce(_columnName, '');
    If _columnName = '' Then
        _returnCode := 'U5201';
        RAISE EXCEPTION 'Column name was blank';
    End If;

    If public.has_whitespace_chars(_columnName, 0) Then
        If Position(chr(9) In _columnName) > 0 Then
            RAISE EXCEPTION 'Column name cannot contain tabs';
        Else
            RAISE EXCEPTION 'Column name cannot contain spaces';
        End If;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    --
    SELECT prep_column_id
    INTO _tmp
    FROM  t_prep_lc_column
    WHERE prep_column = _columnName
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _mode = 'update' And _myRowCount = 0 Then
        _message := 'No entry could be found in database for update';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _mode = 'add' And _myRowCount > 0 Then
        _message := 'Cannot add a duplicate entry';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    If _mode = 'add' Then

        INSERT INTO t_prep_lc_column (
            prep_column,
            mfg_name,
            mfg_model,
            mfg_serial,
            packing_mfg,
            packing_type,
            particle_size,
            particle_type,
            column_inner_dia,
            column_outer_dia,
            length,
            state,
            operator_username,
            comment
        ) VALUES (
            _columnName,
            _mfgName,
            _mfgModel,
            _mfgSerialNumber,
            _packingMfg,
            _packingType,
            _particlesize,
            _particletype,
            _columnInnerDia,
            _columnOuterDia,
            _length,
            _state,
            _operatorUsername,
            _comment
        )
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    End If; -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If _mode = 'update' Then

        UPDATE t_prep_lc_column
        SET
            mfg_name = _mfgName,
            mfg_model = _mfgModel,
            mfg_serial = _mfgSerialNumber,
            packing_mfg = _packingMfg,
            packing_type = _packingType,
            particle_size = _particlesize,
            particle_type = _particletype,
            column_inner_dia = _columnInnerDia,
            column_outer_dia = _columnOuterDia,
            length = _length,
            state = _state,
            operator_username = _operatorUsername,
            comment = _comment
        WHERE
            prep_column = _columnName

    End If;

END
$$;

COMMENT ON PROCEDURE public.add_update_prep_lc_column IS 'AddUpdatePrepLCColumn';
