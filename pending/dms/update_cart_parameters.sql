--
CREATE OR REPLACE PROCEDURE public.update_cart_parameters
(
    _mode text,
    _requestID int,
    INOUT _newValue text,
    INOUT _message text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Changes cart parameters for given requested run
**      This procedure is used by AddUpdateDataset
**
**  Arguments:
**    _mode         Type of update being performed ('CartName', 'RunStart', 'RunFinish', 'RunStatus', or 'InternalStandard')
**    _requestID    ID of scheduled run being updated
**    _newValue     New vale that is being set, or value retured, depending on mode
**    _message      Output: error message
**
**  Auth:   grk
**  Date:   12/16/2003
**          02/27/2006 grk - added cart ID stuff
**          05/10/2006 grk - added verification of request ID
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          04/02/2013 mem - Now using _message to return errors looking up cart name from T_LC_Cart
**          01/09/2017 mem - Update _message when using RAISERROR
**          01/10/2023 mem - Include previous _message text when updating @message
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _dt timestamp;
    _tmp int;
    _cartID int;
    _usageMessage text;
BEGIN
    _message := '';

    _mode = Coalesce(_mode, 'InvalidMode');
    _requestID = Coalesce(_requestID, 0);

    ---------------------------------------------------
    -- Verify that request ID is correct
    ---------------------------------------------------

    SELECT request_id
    INTO _tmp
    FROM t_requested_run
    WHERE request_id = _requestID;

    If Not FOUND Then
        _message := 'Request ID not found';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    If _mode::citext = 'CartName' Then
        ---------------------------------------------------
        -- Resolve ID for LC Cart and update requested run table
        ---------------------------------------------------

        SELECT cart_id
        INTO _cartID
        FROM t_lc_cart
        WHERE cart_name = _newValue;

        If Not FOUND Then
            _message := 'Invalid LC Cart name "' || _newValue || '"';
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
        Else
            -- Note: Only update the value if Cart_ID has changed
            --
            UPDATE t_requested_run
            SET    cart_id = _cartID
            WHERE (request_id = _requestID AND cart_id <> _cartID)
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount < 1 Then
                _myRowCount := 1;
            End If;
        End If;
    End If;

    If _mode::citext = 'RunStatus' Then
        UPDATE t_requested_run
        SET    note = _newValue
        WHERE (request_id = _requestID)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    End If;

    If _mode::citext = 'RunStart' Then
        If _newValue = '' Then
            _dt := CURRENT_TIMESTAMP;
        Else
            _dt := cast(_newValue as timestamp);
        End If;

        UPDATE t_requested_run
        SET    request_run_start = _dt
        WHERE (request_id = _requestID)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    End If;

    If _mode::citext = 'RunFinish' Then
        If _newValue = '' Then
            _dt := CURRENT_TIMESTAMP;
        Else
            _dt := cast(_newValue as timestamp);
        End If;

        UPDATE t_requested_run
        SET     request_run_finish = _dt
        WHERE (request_id = _requestID)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    End If;

    If _mode::citext = 'InternalStandard' Then
        UPDATE t_requested_run
        SET    request_internal_standard = _newValue
        WHERE (request_id = _requestID)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := 'Request ' || _requestID::text;
    Call post_usage_log_entry ('UpdateCartParameters', _usageMessage);

    ---------------------------------------------------
    -- Report any errors
    ---------------------------------------------------
    If _myRowCount = 0 Then
        _message := 'operation failed for mode ' || _mode;
        RAISE WARNING '%', _message;

        If _returnCode = '' Then
            _returnCode := 'U5210';
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE public.update_cart_parameters IS 'UpdateCartParameters';
