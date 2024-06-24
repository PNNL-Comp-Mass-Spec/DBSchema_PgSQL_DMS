--
-- Name: do_material_item_operation(text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.do_material_item_operation(IN _name text, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Do an operation on an item in a container, using the item name
**
**      The only supported action is to retire an experiment or biomaterial
**
**  Arguments:
**    _name         Item name (biomaterial name, experiment name, or experiment ID)
**    _mode         Mode: 'retire_biomaterial', 'retire_experiment'
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Username of the calling user
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
**          12/10/2023 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
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
    _itemList text;
    _newValue text;
    _comment text;

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

        _name := Trim(Coalesce(_name, ''));
        _mode := Trim(Lower(Coalesce(_mode, '')));

        If _mode = '' Then
            RAISE EXCEPTION 'Material item operation mode must be specified';
        End If;

        If Not _mode In ('retire_biomaterial', 'retire_experiment') Then
            RAISE EXCEPTION 'Material item operation mode must be retire_biomaterial or retire_experiment, not %', _mode;
        End If;

        If _name = '' Then
            RAISE EXCEPTION 'Material name not defined; cannot retire';
        End If;

        ---------------------------------------------------
        -- Convert name to ID
        ---------------------------------------------------

        If _mode = 'retire_biomaterial' Then
            -- Resolve biomaterial name to ID
            _typeTag := 'B';

            SELECT Biomaterial_ID
            INTO _tmpID
            FROM t_biomaterial
            WHERE Biomaterial_Name = _name::citext;
        End If;

        If _mode = 'retire_experiment' Then
            -- Resolve experiment name to ID
            _typeTag := 'E';

            _experimentID := public.try_cast(_name, null::int);

            If Coalesce(_experimentID, 0) > 0 And Not Exists (SELECT exp_id FROM t_experiments WHERE experiment = _name::citext) Then
                _tmpID := _experimentID;
            Else
                SELECT exp_id
                INTO _tmpID
                FROM t_experiments
                WHERE experiment = _name::citext;
            End If;
        End If;

        If Coalesce(_tmpID, 0) = 0 Then
            RAISE EXCEPTION 'Could not find % "%" (mode %)',
                        CASE WHEN _typeTag = 'B' THEN 'biomaterial' ELSE 'experiment' END,
                        _name,
                        _mode;
        End If;


        _logErrors := true;

        ---------------------------------------------------
        -- Retire the experiments using procedure update_material_items
        ---------------------------------------------------

        _itemList := format('%s:%s', _typeTag, _tmpID);
        _newValue := '';
        _comment := '';

        CALL public.update_material_items (
                        _mode        => 'retire_items',
                        _itemList    => _itemList,
                        _itemType    => 'mixed_material',
                        _newValue    => _newValue,
                        _comment     => _comment,
                        _message     => _message,       -- Output
                        _returnCode  => _returnCode,    -- Output
                        _callingUser => _callingUser);

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _message;
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


ALTER PROCEDURE public.do_material_item_operation(IN _name text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE do_material_item_operation(IN _name text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.do_material_item_operation(IN _name text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DoMaterialItemOperation';

