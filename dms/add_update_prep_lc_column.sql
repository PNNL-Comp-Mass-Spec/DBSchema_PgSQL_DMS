--
-- Name: add_update_prep_lc_column(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_prep_lc_column(IN _columnname text, IN _mfgname text, IN _mfgmodel text, IN _mfgserialnumber text, IN _packingmfg text, IN _packingtype text, IN _particlesize text, IN _particletype text, IN _columninnerdia text, IN _columnouterdia text, IN _length text, IN _state text, IN _operatorusername text, IN _comment text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing prep LC column
**
**  Arguments:
**    _columnName           Prep LC column name
**    _mfgName              Manufacturer name
**    _mfgModel             Manufacturer model
**    _mfgSerialNumber      Manufacturer serial number
**    _packingMfg           Packing manufacturer
**    _packingType          Packing type
**    _particleSize         Particle size
**    _particleType         Particle type
**    _columnInnerDia       Column inner diameter
**    _columnOuterDia       Column outer diameter
**    _length               Column length
**    _state                State: 'New', 'Active', or 'Retired'
**    _operatorUsername     Username of the DMS user to associate with the column
**    _comment              Comment
**    _mode                 Mode: 'add' or 'update'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user (unused by this procedure)
**
**  Auth:   grk
**  Date:   07/29/2009 grk - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          04/11/2022 mem - Check for whitespace in _columnName
**          01/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _existingCount int;
    _existingID int;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _columnName       := Trim(Coalesce(_columnName, ''));
    _mfgName          := Trim(Coalesce(_mfgName, ''));
    _mfgModel         := Trim(Coalesce(_mfgModel, ''));
    _mfgSerialNumber  := Trim(Coalesce(_mfgSerialNumber, ''));
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
        _returnCode := 'U5201';
        RAISE EXCEPTION 'Column name must be specified';
    End If;

    If public.has_whitespace_chars(_columnName, _allowspace => false) Then
        If Position(chr(9) In _columnName) > 0 Then
            _returnCode := 'U5202';
            RAISE EXCEPTION 'Column name cannot contain tabs';
        Else
            _returnCode := 'U5203';
            RAISE EXCEPTION 'Column name cannot contain spaces';
        End If;
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    SELECT prep_column_id
    INTO _existingID
    FROM  t_prep_lc_column
    WHERE prep_column = _columnName::citext;

    GET DIAGNOSTICS _existingCount = ROW_COUNT;

    If _mode = 'update' And _existingCount = 0 Then
        _message := format('Cannot update: prep LC column "%s" does not exist', _columnName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    If _mode = 'add' And _existingCount > 0 Then
        _message := format('Cannot add: prep LC column "%s" already exists', _columnName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
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
            _particleSize,
            _particleType,
            _columnInnerDia,
            _columnOuterDia,
            _length,
            _state,
            _operatorUsername,
            _comment
        );

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_prep_lc_column
        SET mfg_name          = _mfgName,
            mfg_model         = _mfgModel,
            mfg_serial        = _mfgSerialNumber,
            packing_mfg       = _packingMfg,
            packing_type      = _packingType,
            particle_size     = _particleSize,
            particle_type     = _particleType,
            column_inner_dia  = _columnInnerDia,
            column_outer_dia  = _columnOuterDia,
            length            = _length,
            state             = _state,
            operator_username = _operatorUsername,
            comment           = _comment
        WHERE prep_column = _columnName::citext;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_prep_lc_column(IN _columnname text, IN _mfgname text, IN _mfgmodel text, IN _mfgserialnumber text, IN _packingmfg text, IN _packingtype text, IN _particlesize text, IN _particletype text, IN _columninnerdia text, IN _columnouterdia text, IN _length text, IN _state text, IN _operatorusername text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_prep_lc_column(IN _columnname text, IN _mfgname text, IN _mfgmodel text, IN _mfgserialnumber text, IN _packingmfg text, IN _packingtype text, IN _particlesize text, IN _particletype text, IN _columninnerdia text, IN _columnouterdia text, IN _length text, IN _state text, IN _operatorusername text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_prep_lc_column(IN _columnname text, IN _mfgname text, IN _mfgmodel text, IN _mfgserialnumber text, IN _packingmfg text, IN _packingtype text, IN _particlesize text, IN _particletype text, IN _columninnerdia text, IN _columnouterdia text, IN _length text, IN _state text, IN _operatorusername text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdatePrepLCColumn';

