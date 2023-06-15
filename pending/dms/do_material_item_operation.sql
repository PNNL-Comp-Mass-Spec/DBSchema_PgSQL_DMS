--
CREATE OR REPLACE PROCEDURE public.do_material_item_operation
(
    _name text,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Do an operation on an item, using the item name
**
**  Arguments:
**    _name   Item name (biomaterial name, experiment name, or experiment ID)
**    _mode   'retire_biomaterial', 'retire_experiment'
**
**  Auth:   grk
**  Date:   07/23/2008 grk - Initial version (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**          10/01/2009 mem - Expanded error message
**          08/19/2010 grk - Use try-catch for error handling
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/25/2019 mem - Allow _name to be an experiment ID, which happens if 'Retire Experiment' is clicked at https://dms2.pnl.gov/experimentid/show/123456
**          05/24/2022 mem - Validate parameters
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _experimentID int;
    _tmpID int := 0;
    _typeTag text := '';
    _iMode text,
    _itemList text,
    _itemType text,
    _newValue text,
    _comment text

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
        -- Verify input values
        ---------------------------------------------------

        _name := Trim(Coalesce(_name, ''));
        _mode := Trim(Lower(Coalesce(_mode, '')));

        If _mode = '' Then
            RAISE EXCEPTION 'Material item operation mode not defined';
        End If;

        If Not _mode::citext In ('retire_biomaterial', 'retire_experiment') Then
            RAISE EXCEPTION 'Material item operation mode must be retire_biomaterial or retire_experiment, not %', _mode;
        End If;

        If _name = '' Then
            RAISE EXCEPTION 'Material name not defined; cannot retire';
        End If;

        ---------------------------------------------------
        -- Convert name to ID
        ---------------------------------------------------

        If _mode = 'retire_biomaterial' Then
            -- Look up biomaterial ID from the name
            _typeTag := 'B';

            SELECT Biomaterial_ID
            INTO _tmpID
            FROM T_Biomaterial
            WHERE Biomaterial_Name = _name;
        End If;

        If _mode = 'retire_experiment' Then
            -- Look up experiment ID from the name or ID
            _typeTag := 'E';

            _experimentID := public.try_cast(_name, null::int);

            If Coalesce(_experimentID, 0) > 0 And Not Exists (SELECT * FROM t_experiments WHERE experiment = _name) Then
                _tmpID := _experimentID;
            Else
                SELECT exp_id
                INTO _tmpID
                FROM t_experiments
                WHERE experiment = _name;
            End If;
        End If;

        If _tmpID = 0 Then
            RAISE EXCEPTION 'Could not find the material item for mode "%", name "%"', _mode, _name;
        Else

            _logErrors := true;

            ---------------------------------------------------
            -- Call the material update function
            ---------------------------------------------------

            _iMode := 'retire_items';
            _itemList := format('%s:%s', _typeTag, _tmpID);
            _itemType := 'mixed_material';
            _newValue := '';
            _comment := '';

            CALL update_material_items
                        _iMode,         -- 'retire_item'
                        _itemList,
                        _itemType,      -- 'mixed_material'
                        _newValue,
                        _comment,
                        _message => _message,           -- Output
                        _returnCode => _returnCode,     -- Output
                        _callingUser => _callingUser);

            If _returnCode <> '' Then
                RAISE EXCEPTION '%', _message;
            End If;
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

COMMENT ON PROCEDURE public.do_material_item_operation IS 'DoMaterialItemOperation';

