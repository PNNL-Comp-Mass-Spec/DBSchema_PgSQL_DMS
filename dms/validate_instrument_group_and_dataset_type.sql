--
-- Name: validate_instrument_group_and_dataset_type(text, text, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.validate_instrument_group_and_dataset_type(IN _datasettype text, INOUT _instrumentgroup text, INOUT _datasettypeid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validates the dataset type for the given instrument group
**
**  Arguments:
**    _datasetType          Dataset type name
**    _instrumentGroup      Instrument group name (allowed to be an empty string)
**                          This procedure properly capitalizes the group name, updating this argument
**    _datasetTypeID        Output: dataset type ID
**
**  Auth:   mem
**  Date:   08/27/2010 mem - Initial version
**          09/09/2010 mem - Removed print statements
**          07/04/2012 grk - Added handling for 'Tracking' type
**          11/12/2013 mem - Changed _instrumentName to be an input/output parameter
**          03/25/2014 mem - Now auto-updating dataset type from HMS-HMSn to HMS-HCD-HMSn for group QExactive
**          09/07/2023 mem - Ported to PostgreSQL
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _allowedDatasetTypes text;
    _instrumentGroupMatch text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetType     := Trim(Coalesce(_datasetType, ''));
    _instrumentGroup := Trim(Coalesce(_instrumentGroup, ''));
    _datasetTypeID   := 0;

    ---------------------------------------------------
    -- Verify that dataset type is valid
    -- and get its id number
    ---------------------------------------------------

    _datasetTypeID := public.get_dataset_type_id(_datasetType);

    -- No further validation required for certain dataset types
    -- In particular, dataset type 100 (Tracking)
    If _datasetTypeID = 100 Then
        RETURN;
    End If;

    If _datasetTypeID = 0 Then
        _message := format('Could not find entry in database for dataset type "%s"', _datasetType);
        _returnCode := 'U5018';
        RETURN;
    End If;

    -- Possibly auto-update the dataset type
    If _instrumentGroup::citext = 'QExactive' And _datasetType::citext In ('HMS-HMSn') Then
        _datasetType := 'HMS-HCD-HMSn';
    End If;

    ---------------------------------------------------
    -- Verify that dataset type is valid for given instrument group
    ---------------------------------------------------

    If _instrumentGroup <> '' Then
        SELECT instrument_group
        INTO _instrumentGroupMatch
        FROM t_instrument_group
        WHERE instrument_group = _instrumentGroup::citext;

        If Not FOUND Then
            _message := format('Invalid instrument group: %s', _instrumentGroup);
            _returnCode := 'U5013';
            RETURN;
        Else
            _instrumentGroup := _instrumentGroupMatch;
        End If;

        If Not Exists (SELECT instrument_group
                       FROM t_instrument_group_allowed_ds_type
                       WHERE instrument_group = _instrumentGroup::citext AND
                             dataset_type = _datasetType::citext
                      ) Then

            SELECT string_agg(dataset_type, ', ' ORDER BY dataset_type)
            INTO _allowedDatasetTypes
            FROM t_instrument_group_allowed_ds_type
            WHERE instrument_group = _instrumentGroup::citext;

            _message := format('Dataset type "%s" is invalid for instrument group "%s"; valid types are "%s"',
                                _datasetType, _instrumentGroup, Coalesce(_allowedDatasetTypes, '??'));

            _returnCode := 'U5014';
            RETURN;
        End If;

    End If;

END
$$;


ALTER PROCEDURE public.validate_instrument_group_and_dataset_type(IN _datasettype text, INOUT _instrumentgroup text, INOUT _datasettypeid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_instrument_group_and_dataset_type(IN _datasettype text, INOUT _instrumentgroup text, INOUT _datasettypeid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.validate_instrument_group_and_dataset_type(IN _datasettype text, INOUT _instrumentgroup text, INOUT _datasettypeid integer, INOUT _message text, INOUT _returncode text) IS 'ValidateInstrumentGroupAndDatasetType';

