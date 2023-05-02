--
CREATE OR REPLACE PROCEDURE public.validate_instrument_group_and_dataset_type
(
    _datasetType text,
    INOUT _instrumentGroup text,
    INOUT _datasetTypeID int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Validates the dataset type for the given instrument group
**
**  Arguments:
**    _instrumentGroup   Input/output parameter
**
**  Auth:   mem
**  Date:   08/27/2010 mem - Initial version
**          09/09/2010 mem - Removed print statements
**          07/04/2012 grk - Added handling for 'Tracking' type
**          11/12/2013 mem - Changed _instrumentName to be an input/output parameter
**          03/25/2014 mem - Now auto-updating dataset type from HMS-HMSn to HMS-HCD-HMSn for group QExactive
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _allowedDatasetTypes text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetType := Coalesce(_datasetType, '');
    _instrumentGroup := Coalesce(_instrumentGroup, '');
    _datasetTypeID := 0;
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that dataset type is valid
    -- and get its id number
    ---------------------------------------------------

    _datasetTypeID := get_dataset_type_id (_datasetType);

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
    If _instrumentGroup::citext = 'QExactive' AND _datasetType::citext IN ('HMS-HMSn') Then
        _datasetType := 'HMS-HCD-HMSn';
    End If;

    ---------------------------------------------------
    -- Verify that dataset type is valid for given instrument group
    ---------------------------------------------------

    If _instrumentGroup <> '' Then
        SELECT instrument_group
        INTO _instrumentGroup
        FROM t_instrument_group
        WHERE instrument_group = _instrumentGroup

        If Not FOUND Then
            _message := 'Invalid instrument group: ' || _instrumentGroup;
            _returnCode := 'U5013';
            RETURN;
        End If;

        If Not Exists (SELECT * FROM t_instrument_group_allowed_ds_type WHERE instrument_group = _instrumentGroup AND dataset_type = _datasetType) Then
            _allowedDatasetTypes := '';

            SELECT string_agg(dataset_type, ', ')
            INTO _allowedDatasetTypes
            FROM t_instrument_group_allowed_ds_type
            WHERE instrument_group = _instrumentGroup
            ORDER BY dataset_type;

            _message := format('Dataset type "%s" is invalid for instrument group "%s"; valid types are "%s"',
                                _datasetType, _instrumentGroup, _allowedDatasetTypes);

            _returnCode := 'U5014';
            RETURN;
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE public.validate_instrument_group_and_dataset_type IS 'ValidateInstrumentGroupAndDatasetType';
