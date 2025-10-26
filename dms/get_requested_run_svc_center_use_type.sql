--
-- Name: get_requested_run_svc_center_use_type(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_requested_run_svc_center_use_type(_requestid integer) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Determines the service center use type for the given requested run
**
**  Arguments:
**    _requestID        Requested run ID
**
**  Example usage:
**      SELECT request_id,
**             request_name,
**             get_requested_run_svc_center_use_type(request_id)
**      FROM t_requested_run
**      WHERE request_id BETWEEN 1250000 AND 1250050;
**
**  Auth:   mem
**  Date:   06/29/2025 mem - Initial release
**          08/21/2025 mem - Rename function and use new procedure name
**
*****************************************************/
DECLARE
    _logErrors boolean := false;
    _rrInfo record;
    _sampleTypeInfo record;
    _sampleTypeName text;
    _serviceTypeID int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _message text;
    _returnCode text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _requestID := Coalesce(_requestID, 0);

    _logErrors := true;

    ---------------------------------------------------
    -- Lookup the associated metadata
    ---------------------------------------------------

    SELECT '' AS dataset,
           E.experiment,
           C.campaign,
           DTN.dataset_type,
           5 AS dataset_rating_id,      -- Released
           InstName.instrument,
           Coalesce(InstName.instrument_group, RR.instrument_group) AS instrument_group,
           SepGroup.acq_length_minutes,
           RR.separation_group
    INTO _rrInfo
    FROM t_requested_run RR
         INNER JOIN t_experiments E
           ON RR.exp_id = E.exp_id
         INNER JOIN t_campaign C
           ON E.campaign_id = C.campaign_id
         INNER JOIN t_dataset_type_name DTN
           ON RR.request_type_id = DTN.dataset_type_id
         INNER JOIN t_separation_group SepGroup
           ON RR.separation_group = SepGroup.separation_group
         LEFT OUTER JOIN t_instrument_name InstName
           ON RR.queue_instrument_id = InstName.instrument_id
    WHERE request_id = _requestID;

    ---------------------------------------------------
    -- Determine the most common sample type ID for the separation group
    ---------------------------------------------------

    SELECT separation_group, sample_type_id, separation_type_count
    INTO _sampleTypeInfo
    FROM ( SELECT separation_group,
                  sample_type_id,
                  Separation_type_Count,
           row_number() OVER ( PARTITION BY separation_group ORDER BY Separation_type_Count DESC ) AS
             Usage_Rank
           FROM ( SELECT separation_group,
                         sample_type_id,
                         Count(*) AS Separation_type_Count
                  FROM t_secondary_sep
                  WHERE separation_group = _rrInfo.separation_group
                  GROUP BY separation_group, sample_type_id
                ) GroupQ
         ) CountQ
    WHERE Usage_Rank = 1;

    If FOUND Then
        SELECT name
        INTO _sampleTypeName
        FROM t_secondary_sep_sample_type
        WHERE sample_type_id = _sampleTypeInfo.sample_type_id;

        /*
        RAISE INFO 'Separation group % most commonly has a sample type of % (%); usage count: %',
                   _rrInfo.separation_group,
                   _sampleTypeName,
                   _sampleTypeInfo.sample_type_id,
                   _sampleTypeInfo.separation_type_count;
        */
    End If;

    _sampleTypeName := Coalesce(_sampleTypeName, '');

    ---------------------------------------------------
    -- Determine the service type
    ---------------------------------------------------

    _serviceTypeID := public.get_service_center_use_type (
             _datasetName         => _rrInfo.dataset,
             _experimentName      => _rrInfo.experiment,
             _campaignName        => _rrInfo.campaign,
             _datasetTypeName     => _rrInfo.dataset_type,
             _datasetRatingID     => _rrInfo.dataset_rating_id,
             _instrumentName      => _rrInfo.instrument,
             _instrumentGroupName => _rrInfo.instrument_group,
             _acqLengthMinutes    => _rrInfo.acq_length_minutes,
             _separationTypeName  => '',
             _separationGroupName => _rrInfo.separation_group,
             _sampleTypeName      => _sampleTypeName
        );

    RETURN _serviceTypeID;

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

    If Position(_returnCode In _message) = 0 Then
        _message := format('%s (%s)', _message, _returnCode);
    End If;

    RAISE WARNING '%', _message;

    RETURN 25; -- Ambiguous
END
$$;


ALTER FUNCTION public.get_requested_run_svc_center_use_type(_requestid integer) OWNER TO d3l243;

