--
CREATE OR REPLACE PROCEDURE public.add_update_lc_cart_settings_history
(
    _id int,
    _cartName text,
    _valveToColumnExtension text,
    _operatingPressure text,
    _interfaceConfiguration text,
    _valveToColumnExtensionDimensions text,
    _mixerVolume text,
    _sampleLoopVolume text,
    _sampleLoadingTime text,
    _splitFlowRate text,
    _splitColumnDimensions text,
    _purgeFlowRate text,
    _purgeColumnDimensions text,
    _purgeVolume text,
    _acquisitionTime text,
    _solventA text,
    _solventB text,
    _comment text,
    _dateOfChange text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing T_LC_Cart_Settings_History
**
**  Arguments:
**    _id
**    _cartName
**    _valveToColumnExtension
**    _operatingPressure
**    _interfaceConfiguration
**    _valveToColumnExtensionDimensions
**    _mixerVolume
**    _sampleLoopVolume
**    _sampleLoadingTime
**    _splitFlowRate
**    _splitColumnDimensions
**    _purgeFlowRate
**    _purgeColumnDimensions
**    _purgeVolume
**    _acquisitionTime
**    _solventA
**    _solventB
**    _comment
**    _dateOfChange
**    _mode                                 Mode: 'add' or 'update'
**    _message                              Output message
**    _returnCode                           Return code
**    _callingUser                          Calling user username
**
**  Auth:   grk
**  Date:   09/29/2008
**          10/21/2008 grk - Added parameters _solventA and _solventB
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _cartID int;
    _tmp int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _cartName := Trim(Coalesce(_cartName, ''));
    _mode     := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Resolve cart name to ID
    ---------------------------------------------------

    SELECT cart_id
    INTO _cartID
    FROM  t_lc_cart
    WHERE cart_name = _cartName;

    If Not FOUND Then
        _message := 'Could not find cart';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        -- Cannot update a non-existent entry
        --
        SELECT entry_id
        INTO _tmp
        FROM t_lc_cart_settings_history
        WHERE entry_id = _id;

        If Not FOUND Then
            _message := 'No entry could be found in database for update';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        INSERT INTO t_lc_cart_settings_history (
            valve_to_column_extension,
            operating_pressure,
            interface_configuration,
            valve_to_column_extension_dimensions,
            mixer_volume,
            sample_loop_volume,
            sample_loading_time,
            split_flow_rate,
            split_column_dimensions,
            purge_flow_rate,
            purge_column_dimensions,
            purge_volume,
            acquisition_time,
            solvent_a,
            solvent_b,
            cart_id,
            comment,
            date_of_change,
            entered_by
        ) VALUES (
            _valveToColumnExtension,
            _operatingPressure,
            _interfaceConfiguration,
            _valveToColumnExtensionDimensions,
            _mixerVolume,
            _sampleLoopVolume,
            _sampleLoadingTime,
            _splitFlowRate,
            _splitColumnDimensions,
            _purgeFlowRate,
            _purgeColumnDimensions,
            _purgeVolume,
            _acquisitionTime,
            _solventA,
            _solventB,
            _cartID,
            _comment,
            _dateOfChange,
            _callingUser
        )
        RETURNING entry_id
        INTO _id;

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_lc_cart_settings_history
        SET valve_to_column_extension = _valveToColumnExtension,
            operating_pressure = _operatingPressure,
            interface_configuration = _interfaceConfiguration,
            valve_to_column_extension_dimensions = _valveToColumnExtensionDimensions,
            mixer_volume = _mixerVolume,
            sample_loop_volume = _sampleLoopVolume,
            sample_loading_time = _sampleLoadingTime,
            split_flow_rate = _splitFlowRate,
            split_column_dimensions = _splitColumnDimensions,
            purge_flow_rate = _purgeFlowRate,
            purge_column_dimensions = _purgeColumnDimensions,
            purge_volume = _purgeVolume,
            acquisition_time = _acquisitionTime,
            solvent_a = _solventA,
            solvent_b = _solventB,
            comment = _comment,
            date_of_change = _dateOfChange,
            entered_by = _callingUser
        WHERE entry_id = _id;

    End If;

END
$$;

COMMENT ON PROCEDURE public.add_update_lc_cart_settings_history IS 'AddUpdateLCCartSettingsHistory';
