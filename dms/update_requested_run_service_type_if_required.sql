--
-- Name: update_requested_run_service_type_if_required(integer, boolean, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_requested_run_service_type_if_required(IN _requestid integer, IN _infoonly boolean DEFAULT false, IN _logdebugmessages boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates service_type_id in t_requested_run if the auto-defined value differs from the current value
**      However, if the current service type ID is non-zero, will not change the value to 25 (Ambiguous)
**      See also table svc.t_service_type
**
**  Arguments:
**    _requestID            Requested run ID
**    _infoOnly             When true, show the old and new values for service_type_id
**    _logDebugMessages     When true, show additional status messages
**
**  Example Usage:
**      CALL update_requested_run_service_type_if_required(1250021, _infoOnly => true);
**      CALL update_requested_run_service_type_if_required(1250021, _infoOnly => false);
**      CALL update_requested_run_service_type_if_required(1250021, _logDebugMessages => true);
**
**  Auth:   mem
**  Date:   07/25/2025 mem - Initial release
**          08/20/2025 mem - Reference schema svc instead of cc
**
*****************************************************/
DECLARE
    _currentServiceTypeID smallint;
    _autoDefinedServiceTypeID smallint;
    _debugMsg text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _requestID        := Coalesce(_requestID, 0);
    _infoOnly         := Coalesce(_infoOnly, false);
    _logDebugMessages := Coalesce(_logDebugMessages, false);

    If _infoOnly Then
        RAISE INFO '';
    End If;

    ---------------------------------------------------
    -- Lookup the current service type ID
    ---------------------------------------------------

    SELECT service_type_id
    INTO _currentServiceTypeID
    FROM t_requested_run
    WHERE request_id = _requestID;

    If Not FOUND Then
        RAISE WARNING 'Requested run not found in t_requested_run: %', _requestID;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Obtain the auto-defined service type ID, then update if required
    ---------------------------------------------------

    _autoDefinedServiceTypeID := public.get_requested_run_cc_service_type(_requestID);

    If _currentServiceTypeID = _autoDefinedServiceTypeID Then
        If _infoOnly OR _logDebugMessages Then
            RAISE INFO 'Service type ID for requested run % is already the auto-defined value: %', _requestID, _currentServiceTypeID;
        End If;
    Else
        If _autoDefinedServiceTypeID = 25 And _currentServiceTypeID <> 0 Then
            -- Leave the current service type ID as-is, since it has already been manually defined
            If _infoOnly OR _logDebugMessages Then
                RAISE INFO 'Leaving service type ID as % for requested run %', _currentServiceTypeID, _requestID;
            End If;
        ElsIf _infoOnly Then
            RAISE INFO 'Would change the service type ID from % to % for requested run %', _currentServiceTypeID, _autoDefinedServiceTypeID, _requestID;
        Else
            UPDATE t_requested_run
            SET service_type_id = _autoDefinedServiceTypeID
            WHERE request_id = _requestID;

            If _currentServiceTypeID <> 0 Or _logDebugMessages Then
                _debugMsg := format('Changed cost center service type ID for requested run %s from %s to %s',
                                    _requestID, _currentServiceTypeID, _autoDefinedServiceTypeID);

                CALL post_log_entry ('Normal', _debugMsg, 'update_requested_run_service_type_if_required');
            End If;
        End If;
    End If;
END
$$;


ALTER PROCEDURE public.update_requested_run_service_type_if_required(IN _requestid integer, IN _infoonly boolean, IN _logdebugmessages boolean) OWNER TO d3l243;

