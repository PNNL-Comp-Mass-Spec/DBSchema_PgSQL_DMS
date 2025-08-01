--
-- Name: update_dataset_service_type_if_required(integer, boolean, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_dataset_service_type_if_required(IN _datasetid integer, IN _infoonly boolean DEFAULT false, IN _logdebugmessages boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates service_type_id in t_dataset if the auto-defined value differs from the current value
**      However, if the current service type ID is non-zero, will not change the value to 25 (Ambiguous)
**      See also table cc.t_service_type
**
**  Arguments:
**    _datasetID            Dataset ID
**    _infoOnly             When true, show the old and new values for service_type_id
**    _logDebugMessages     When true, show additional status messages
**
**  Example Usage:
**      CALL update_dataset_service_type_if_required(1100000, _infoOnly => true);
**      CALL update_dataset_service_type_if_required(1100000, _infoOnly => false);
**      CALL update_dataset_service_type_if_required(1100000, _logDebugMessages => true);
**
**  Auth:   mem
**  Date:   07/10/2025 mem - Initial release
**          07/25/2025 mem - Update service_type_id in t_requested_run
**                         - Call RAISE INFO with '' when _infoOnly is true
**
*****************************************************/
DECLARE
    _currentServiceTypeID smallint;
    _autoDefinedServiceTypeID smallint;
    _requestID int;
    _reqRunCurrentServiceTypeID smallint;
    _debugMsg text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetID        := Coalesce(_datasetID, 0);
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
    FROM t_dataset
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        RAISE WARNING 'Dataset ID not found in t_dataset: %', _datasetID;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Obtain the auto-defined service type ID, then update if required
    ---------------------------------------------------

    _autoDefinedServiceTypeID := public.get_dataset_cc_service_type(_datasetID);

    If _currentServiceTypeID = _autoDefinedServiceTypeID Then
        If _infoOnly OR _logDebugMessages Then
            RAISE INFO 'Service type ID for dataset ID % is already the auto-defined value: %', _datasetID, _currentServiceTypeID;
        End If;
    Else
        If _autoDefinedServiceTypeID = 25 And _currentServiceTypeID <> 0 Then
            -- Leave the current service type ID as-is, since it has already been manually defined
            If _infoOnly OR _logDebugMessages Then
                RAISE INFO 'Leaving service type ID as % for dataset ID %', _currentServiceTypeID, _datasetID;
            End If;
        ElsIf _infoOnly Then
            RAISE INFO 'Would change the service type ID from % to % for dataset ID %', _currentServiceTypeID, _autoDefinedServiceTypeID, _datasetID;
        Else
            UPDATE t_dataset
            SET service_type_id = _autoDefinedServiceTypeID
            WHERE dataset_id = _datasetID;

            If _currentServiceTypeID <> 0 Or _logDebugMessages Then
                _debugMsg := format('Changed cost center service type ID for dataset ID %s from %s to %s',
                                    _datasetID, _currentServiceTypeID, _autoDefinedServiceTypeID);

                CALL post_log_entry ('Normal', _debugMsg, 'update_dataset_service_type_if_required');
            End If;

            ---------------------------------------------------
            -- Also update the requested run, if required
            ---------------------------------------------------

            SELECT request_id, service_type_id
            INTO _requestID, _reqRunCurrentServiceTypeID
            FROM t_requested_run
            WHERE dataset_id = _datasetID
            ORDER BY request_id DESC
            LIMIT 1;

            If FOUND And _reqRunCurrentServiceTypeID <> _autoDefinedServiceTypeID Then
                UPDATE t_requested_run
                SET service_type_id = _autoDefinedServiceTypeID
                WHERE dataset_id = _datasetID;

                If _reqRunCurrentServiceTypeID <> 0 Or _logDebugMessages Then
                    _debugMsg := format('Changed cost center service type ID for requested run %s from %s to %s',
                                        _requestID, _reqRunCurrentServiceTypeID, _autoDefinedServiceTypeID);

                    CALL post_log_entry ('Normal', _debugMsg, 'update_dataset_service_type_if_required');
                End If;
            End If;

        End If;
    End If;
END
$$;


ALTER PROCEDURE public.update_dataset_service_type_if_required(IN _datasetid integer, IN _infoonly boolean, IN _logdebugmessages boolean) OWNER TO d3l243;

