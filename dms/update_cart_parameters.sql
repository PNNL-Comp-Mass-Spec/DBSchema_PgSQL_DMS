--
-- Name: update_cart_parameters(text, integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cart_parameters(IN _mode text, IN _requestid integer, IN _newvalue text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Changes cart parameters for given requested run
**      This procedure is used by add_update_dataset
**
**  Arguments:
**    _mode         Type of update being performed ('CartName', 'RunStatus', 'RunStart', 'RunFinish', or 'InternalStandard')
**    _requestID    ID of requested run being updated
**    _newValue     New value to store in t_requested_run for _requestID (see below for more info)
**    _message      Output: error message
**    _returnCode   Output: return code
**
**  Mode descriptions:
**
**      Mode              T_Requested_Run Column      Description
**      ----------------  -------------------------  -----------------------------------------------------------------------------------------------------------------------------------------------------
**      CartName          cart_id                    Store the cart ID that corresponds to the cart name specified by _newValue; if the cart name is invalid, the table is not updated
**      RunStatus         note                       Store the text specified by _newValue (this mode is not used; every row in t_requested_run has an empty string or null in the "note" column)
**      RunStart          request_run_start          Store the requested run start time,  using either the timestamp specified by _newValue, or the current time if _newValue is an empty string (or null)
**      RunFinish         request_run_finish         Store the requested run finish time, using either the timestamp specified by _newValue, or the current time if _newValue is an empty string (or null)
**      InternalStandard  request_internal_standard  Store the internal standard name specified by _newValue
**
**  Auth:   grk
**  Date:   12/16/2003
**          02/27/2006 grk - Added cart ID stuff
**          05/10/2006 grk - Added verification of request ID
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          04/02/2013 mem - Now using _message to return errors looking up cart name from T_LC_Cart
**          01/09/2017 mem - Update _message when using RAISERROR
**          01/10/2023 mem - Include previous _message text when updating @message
**          09/08/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _dt timestamp;
    _tmp int;
    _cartID int;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    _mode      := Trim(Lower(Coalesce(_mode, '')));
    _requestID := Coalesce(_requestID, 0);
    _newValue  := Trim(Coalesce(_newValue, ''));

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

    If _mode::citext = 'CartName' Then
        ---------------------------------------------------
        -- Resolve ID for LC Cart and update requested run table
        ---------------------------------------------------

        SELECT cart_id
        INTO _cartID
        FROM t_lc_cart
        WHERE cart_name = _newValue::citext;

        If Not FOUND Then
            _message := format('Invalid LC Cart name: %s', _newValue);
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
        Else
            -- Note: Only update the value if Cart_ID has changed
            --
            UPDATE t_requested_run
            SET cart_id = _cartID
            WHERE request_id = _requestID AND
                  cart_id <> _cartID;
        End If;
    End If;

    If _mode::citext = 'RunStatus' Then
        UPDATE t_requested_run
        SET note = _newValue
        WHERE request_id = _requestID;
    End If;

    If _mode::citext = 'RunStart' Then
        If _newValue = '' Then
            _dt := CURRENT_TIMESTAMP;
        Else
            _dt := public.try_cast(_newValue, null::timestamp);

            If _dt Is Null Then
                _message := format('Start time is not a valid timestamp: %s', _newValue);
                RAISE WARNING '%', _message;

                _returnCode := 'U5203';
            End If;
        End If;

        If Not _dt Is Null Then
            UPDATE t_requested_run
            SET request_run_start = _dt
            WHERE request_id = _requestID;
        End If;
    End If;

    If _mode::citext = 'RunFinish' Then
        If _newValue = '' Then
            _dt := CURRENT_TIMESTAMP;
        Else
            _dt := public.try_cast(_newValue, null::timestamp);

            If _dt Is Null Then
                _message := format('Finish time is not a valid timestamp: %s', _newValue);
                RAISE WARNING '%', _message;

                _returnCode := 'U5204';
            End If;
        End If;

        If Not _dt Is Null Then
            UPDATE t_requested_run
            SET request_run_finish = _dt
            WHERE request_id = _requestID;
        End If;
    End If;

    If _mode::citext = 'InternalStandard' Then
        UPDATE t_requested_run
        SET request_internal_standard = _newValue
        WHERE request_id = _requestID;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Request %s', _requestID);

    CALL post_usage_log_entry ('update_cart_parameters', _usageMessage);

END
$$;


ALTER PROCEDURE public.update_cart_parameters(IN _mode text, IN _requestid integer, IN _newvalue text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cart_parameters(IN _mode text, IN _requestid integer, IN _newvalue text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_cart_parameters(IN _mode text, IN _requestid integer, IN _newvalue text, INOUT _message text, INOUT _returncode text) IS 'UpdateCartParameters';

