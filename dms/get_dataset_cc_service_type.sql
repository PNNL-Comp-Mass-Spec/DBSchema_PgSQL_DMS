--
-- Name: get_dataset_cc_service_type(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_cc_service_type(_datasetid integer) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Determines the cost center service type for the given dataset
**
**  Arguments:
**    _datasetID        Dataset ID
**
**  Example Usage:
**      SELECT dataset,
**             get_dataset_cc_service_type(dataset_id)
**      FROM t_dataset
**      WHERE dataset_id BETWEEN 1200000 AND 1200100;
**
**  Auth:   mem
**  Date:   06/29/2025 mem - Initial release
**
*****************************************************/
DECLARE
    _logErrors boolean := false;
    _datasetInfo record;
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

    _datasetID := Coalesce(_datasetID, 0);

    _logErrors := true;

    ---------------------------------------------------
    -- Lookup the associated metadata
    ---------------------------------------------------

    SELECT DS.dataset,
           E.experiment,
           C.campaign,
           DTN.dataset_type,
           DS.dataset_rating_id,
           InstName.instrument,
           InstName.instrument_group,
           DS.acq_length_minutes,
           DS.separation_type,
           SS.separation_group,
           SampType.name AS sampleTypeName
    INTO _datasetInfo
    FROM t_dataset DS
         INNER JOIN t_experiments E
           ON DS.exp_id = E.exp_id
         INNER JOIN t_campaign C
           ON E.campaign_id = C.campaign_id
         INNER JOIN t_dataset_type_name DTN
           ON DS.dataset_type_id = DTN.dataset_type_id
         INNER JOIN t_instrument_name InstName
           ON DS.instrument_id = InstName.instrument_id
         INNER JOIN t_secondary_sep SS
           ON DS.separation_type = SS.separation_type
         INNER JOIN t_secondary_sep_sample_type SampType
           ON SS.sample_type_id = SampType.sample_type_id
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Determine the service type
    ---------------------------------------------------

    _serviceTypeID := public.get_cc_service_type (
             _datasetName         => _datasetInfo.dataset,
             _experimentName      => _datasetInfo.experiment,
             _campaignName        => _datasetInfo.campaign,
             _datasetTypeName     => _datasetInfo.dataset_type,
             _datasetRatingID     => _datasetInfo.dataset_rating_id,
             _instrumentName      => _datasetInfo.instrument,
             _instrumentGroupName => _datasetInfo.instrument_group,
             _acqLengthMinutes    => _datasetInfo.acq_length_minutes,
             _separationTypeName  => _datasetInfo.separation_type,
             _separationGroupName => _datasetInfo.separation_group,
             _sampleTypeName      => _datasetInfo.sampleTypeName
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


ALTER FUNCTION public.get_dataset_cc_service_type(_datasetid integer) OWNER TO d3l243;

