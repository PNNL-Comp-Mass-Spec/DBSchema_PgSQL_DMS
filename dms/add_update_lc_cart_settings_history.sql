--
-- Name: add_update_lc_cart_settings_history(integer, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_lc_cart_settings_history(IN _id integer, IN _cartname text, IN _valvetocolumnextension text, IN _operatingpressure text, IN _interfaceconfiguration text, IN _valvetocolumnextensiondimensions text, IN _mixervolume text, IN _sampleloopvolume text, IN _sampleloadingtime text, IN _splitflowrate text, IN _splitcolumndimensions text, IN _purgeflowrate text, IN _purgecolumndimensions text, IN _purgevolume text, IN _acquisitiontime text, IN _solventa text, IN _solventb text, IN _comment text, IN _dateofchange text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing LC cart settings history note
**
**      This procedure is obsolete; it was last used in 2009
**
**  Arguments:
**    _id                                   Entry_id in t_lc_cart_settings_history
**    _cartName                             Cart name
**    _valveToColumnExtension               Valve to column extension
**    _operatingPressure                    Operating pressure
**    _interfaceConfiguration               Interface configuration
**    _valveToColumnExtensionDimensions     Valve to column extension dimensions
**    _mixerVolume                          Mixer volume
**    _sampleLoopVolume                     Sample loop volume
**    _sampleLoadingTime                    Sample loading time
**    _splitFlowRate                        Split flow rate
**    _splitColumnDimensions                Split column dimensions
**    _purgeFlowRate                        Purge flow rate
**    _purgeColumnDimensions                Purge column dimensions
**    _purgeVolume                          Purge volume
**    _acquisitionTime                      Acquisition time
**    _solventA                             Solvent A
**    _solventB                             Solvent B
**    _comment                              Comment
**    _dateOfChange                         Date of change
**    _mode                                 Mode: 'add' or 'update'
**    _message                              Status message
**    _returnCode                           Return code
**    _callingUser                          Username of the calling user
**
**  Auth:   grk
**  Date:   09/29/2008
**          10/21/2008 grk - Added parameters _solventA and _solventB
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          01/13/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _cartID int;
    _parsedDate timestamp;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _cartName    := Trim(Coalesce(_cartName, ''));
    _callingUser := Trim(Coalesce(_callingUser, ''));
    _mode        := Trim(Lower(Coalesce(_mode, '')));

    _parsedDate := public.try_cast(_dateOfChange, null::timestamp);
    _parsedDate := Coalesce(_parsedDate, CURRENT_TIMESTAMP);

    If _cartName = '' Then
        _message := 'LC cart name must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _callingUser = '' Then
        _callingUser = SESSION_USER;
    End If;

    ---------------------------------------------------
    -- Resolve cart name to ID
    ---------------------------------------------------

    SELECT cart_id
    INTO _cartID
    FROM  t_lc_cart
    WHERE cart_name = _cartName::citext;

    If Not FOUND Then
        _message := format('Could not find cart "%s"', _cartName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        If _id Is Null Then
            _message := 'Cannot update: cart settings ID cannot be null';
            RAISE WARNING '%', _message;

            _returnCode := 'U5203';
            RETURN;
        End If;

        If Not Exists (SELECT entry_id FROM t_lc_cart_settings_history WHERE entry_id = _id) Then
            _message := format('Cannot update: LC cart settings ID %s does not exist', _id);
            RAISE WARNING '%', _message;

            _returnCode := 'U5204';
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
            _parsedDate,
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
        SET valve_to_column_extension            = _valveToColumnExtension,
            operating_pressure                   = _operatingPressure,
            interface_configuration              = _interfaceConfiguration,
            valve_to_column_extension_dimensions = _valveToColumnExtensionDimensions,
            mixer_volume                         = _mixerVolume,
            sample_loop_volume                   = _sampleLoopVolume,
            sample_loading_time                  = _sampleLoadingTime,
            split_flow_rate                      = _splitFlowRate,
            split_column_dimensions              = _splitColumnDimensions,
            purge_flow_rate                      = _purgeFlowRate,
            purge_column_dimensions              = _purgeColumnDimensions,
            purge_volume                         = _purgeVolume,
            acquisition_time                     = _acquisitionTime,
            solvent_a                            = _solventA,
            solvent_b                            = _solventB,
            comment                              = _comment,
            date_of_change                       = _parsedDate,
            entered_by                           = _callingUser
        WHERE entry_id = _id;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_lc_cart_settings_history(IN _id integer, IN _cartname text, IN _valvetocolumnextension text, IN _operatingpressure text, IN _interfaceconfiguration text, IN _valvetocolumnextensiondimensions text, IN _mixervolume text, IN _sampleloopvolume text, IN _sampleloadingtime text, IN _splitflowrate text, IN _splitcolumndimensions text, IN _purgeflowrate text, IN _purgecolumndimensions text, IN _purgevolume text, IN _acquisitiontime text, IN _solventa text, IN _solventb text, IN _comment text, IN _dateofchange text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_lc_cart_settings_history(IN _id integer, IN _cartname text, IN _valvetocolumnextension text, IN _operatingpressure text, IN _interfaceconfiguration text, IN _valvetocolumnextensiondimensions text, IN _mixervolume text, IN _sampleloopvolume text, IN _sampleloadingtime text, IN _splitflowrate text, IN _splitcolumndimensions text, IN _purgeflowrate text, IN _purgecolumndimensions text, IN _purgevolume text, IN _acquisitiontime text, IN _solventa text, IN _solventb text, IN _comment text, IN _dateofchange text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_lc_cart_settings_history(IN _id integer, IN _cartname text, IN _valvetocolumnextension text, IN _operatingpressure text, IN _interfaceconfiguration text, IN _valvetocolumnextensiondimensions text, IN _mixervolume text, IN _sampleloopvolume text, IN _sampleloadingtime text, IN _splitflowrate text, IN _splitcolumndimensions text, IN _purgeflowrate text, IN _purgecolumndimensions text, IN _purgevolume text, IN _acquisitiontime text, IN _solventa text, IN _solventb text, IN _comment text, IN _dateofchange text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateLCCartSettingsHistory';

