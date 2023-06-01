--
CREATE OR REPLACE PROCEDURE public.add_update_lc_cart_configuration
(
    _id int,
    _configName text,
    _description text,
    _autosampler text,
    _customValveConfig text,
    _pumps text,
    _primaryInjectionVolume text,
    _primaryMobilePhases text,
    _primaryTrapColumn text,
    _primaryTrapFlowRate text,
    _primaryTrapTime text,
    _primaryTrapMobilePhase text,
    _primaryAnalyticalColumn text,
    _primaryColumnTemperature text,
    _primaryAnalyticalFlowRate text,
    _primaryGradient text,
    _massSpecStartDelay text,
    _upstreamInjectionVolume text,
    _upstreamMobilePhases text,
    _upstreamTrapColumn text,
    _upstreamTrapFlowRate text,
    _upstreamAnalyticalColumn text,
    _upstreamColumnTemperature text,
    _upstreamAnalyticalFlowRate text,
    _upstreamFractionationProfile text,
    _upstreamFractionationDetails text,
    _entryUser text = '',
    _state text = 'Active',
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
**      Adds new or edits existing T_LC_Cart_Configuration entry
**
**  Arguments:
**    _entryUser   User who entered the LC Cart Configuration entry; defaults to _callingUser if empty
**    _state       Active, Inactive, Invalid, or Override (see comments below)
**    _mode        or 'update'
**
**  Auth:   mem
**  Date:   02/02/2017 mem - Initial release
**          02/22/2017 mem - Add several new parameters to match the updated columns in T_LC_Cart_Configuration
**          02/23/2017 mem - Validate the config name
**          02/24/2017 mem - Add parameters _primaryTrapTime and _primaryTrapMobilePhase
**                         - Allow changing state even if the Cart Config is associated with datasets
**          02/28/2017 mem - Remove parameter _cartName
**                         - Validate that _configName starts with a valid cart name
**          03/03/2017 mem - Add parameter _entryUser
**          09/17/2018 mem - Update cart config name error message
**          03/03/2021 mem - Update admin-required message
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _badCh text;
    _underscoreLoc int;
    _cartName text;
    _cartID int := 0;
    _existingName text := '';
    _oldState text := '';
    _ignoreDatasetChecks int := 0;
    _existingEntryUser text := '';
    _conflictID int := 0;
    _datasetCount int := 0;
    _maxDatasetID int := 0;
    _datasetDescription text;
    _datasetName text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _id := Coalesce(_id, 0);
    _configName := Coalesce(_configName, '');
    _state := Coalesce(_state, 'Active');
    _entryUser := Coalesce(_entryUser, '');
    _callingUser := Coalesce(_callingUser, '');
    _mode := Trim(Lower(Coalesce(_mode, 'add')));

    If _state = '' Then
        _state := 'Active';
    End If;

    ---------------------------------------------------
    -- Validate _state
    -- Note that table t_lc_cart_configuration also has a check constraint on the cart_config_state field
    --
    -- Override can only be used when _callingUser is a user with DMS_Infrastructure_Administration privileges
    -- When _state is Override, the state will be left unchanged, but data can still be updated
    -- even if the cart config is already associated with datasets
    ---------------------------------------------------
    --
    If Not _state::citext IN ('Active', 'Inactive', 'Invalid', 'Override') Then
        _message := format('Cart config state must be Active, Inactive, or Invalid; %s is not allowed', _state);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If Not Exists (Select username From t_users Where username = _callingUser) Then
        _callingUser := null;
    ElsIf _entryUser = '' Then
        _entryUser := _callingUser;
    End If;

    If _state = 'Override' and _mode <> 'update' Then
        _message := format('Cart config state must be Active, Inactive, or Invalid when _mode is %s; %s is not allowed', _mode, _state);
    End If;

    ---------------------------------------------------
    -- Validate the cart configuration name
    -- First assure that it does not have invalid characters and is long enough
    ---------------------------------------------------

    _badCh := public.validate_chr(_configName, '');

    If _badCh <> '' Then
        If _badCh = 'space' Then
            _message := 'LC Cart Configuration name may not contain spaces';
        Else
            _message := format('LC Cart Configuration name may not contain the character(s) "%s"', _badCh);
        End If;

        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If char_length(_configName) < 6 Then
        _message := format('LC Cart Configuration name must be at least 6 characters in length; currently %s characters', char_length(_configName));
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Next assure that it starts with a valid cart name followed by an underscore, or starts with 'Unknown_'
    ---------------------------------------------------
    --

    _underscoreLoc := Position('_' In _configName);

    If _underscoreLoc <=1 Then
        _message := 'Cart Config name must start with a valid LC cart name, followed by an underscore';
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    _cartName := Substring(_configName, 1, _underscoreLoc-1);

    If _cartName = 'Unknown' Then
        _cartName := 'No_Cart';
    End If;

    ---------------------------------------------------
    -- Resolve cart name to ID
    ---------------------------------------------------
    --
    --
    SELECT cart_id
    INTO _cartID
    FROM  t_lc_cart
    WHERE cart_name = _cartName

    If Not FOUND Then
        _message := format('Cart Config name must start with a valid LC cart name, followed by an underscore; unknown cart: %s', _cartName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------
    --
    If _mode = 'update' Then
        -- Lookup the current name and state

        SELECT cart_config_name,
               cart_config_state,
               entered_by
        INTO _existingName, _oldState, _existingEntryUser
        FROM t_lc_cart_configuration
        WHERE cart_config_id = _id

        If Not FOUND Then
            _message := 'No entry could be found in database for update';
            RAISE WARNING '%', _message;

            _returnCode := 'U5206';
            RETURN;
        End If;

        If _state = 'Override' Then
            If Exists ( Then
                SELECT *;
            End If;
                FROM t_users U
                    INNER JOIN t_user_operations_permissions OpsPerms
                    ON U.user_id = OpsPerms.user_id
                    INNER JOIN t_user_operations UserOps
                    ON OpsPerms.operation_id = UserOps.user_id
                WHERE U.username = _callingUser AND
                    UserOps.operation = 'DMS_Infrastructure_Administration')
            Begin
                -- Admin user is updating details for an LC Cart Config that is already associated with datasets
                -- Use the existing state
                _state := _oldState;
                _ignoreDatasetChecks := 1;
            Else
                _message := format('Cart config state must be Active, Inactive, or Invalid; %s is not allowed', _state);
                RAISE WARNING '%', _message;

                _returnCode := 'U5207';
                RETURN;
            End If;
        End If;

        If _configName <> _existingName Then

            SELECT cart_config_id
            INTO _conflictID
            FROM t_lc_cart_configuration
            WHERE cart_config_name = _configName

            If _conflictID > 0 Then
                _message := format('Cannot rename config from %s to %s because the new name is already in use by ID %s',
                                    _existingName, _configName, _conflictID);
                RAISE WARNING '%', _message;

                _returnCode := 'U5208';
                RETURN;
            End If;
        End If;

        If _entryUser = '' Then
            _entryUser := _existingEntryUser;
        End If;

        ---------------------------------------------------
        -- Only allow updating the state of Cart Config items that are associated with a dataset
        ---------------------------------------------------
        --
        If _ignoreDatasetChecks = 0 And Exists (Select * FROM t_dataset Where cart_config_id = _id) Then

            SELECT COUNT(*),
                   MAX(dataset_id)
            INTO _datasetCount, _maxDatasetID
            FROM t_dataset
            WHERE cart_config_id = _id

            SELECT dataset
            INTO _datasetName
            FROM t_dataset
            WHERE dataset_id = _maxDatasetID

            If _datasetCount = 1 Then
                _datasetDescription := format('dataset %s', _datasetName);
            Else
                _datasetDescription := format('%s datasets' _datasetCount);
            End If;

            If _state <> _oldState Then
                UPDATE t_lc_cart_configuration
                SET cart_config_state = _state
                WHERE cart_config_id = _id

                _message := format('Updated state to %s; any other changes were ignored because this cart config is associated with %s',
                                    _state, _datasetDescription);
                RETURN;
            End If;

            _message := format('LC cart config ID %s is associated with %s, most recently %s; contact a DMS admin to update the configuration (using special state Override)',
                                _id, _datasetDescription, _datasetName);

            RAISE WARNING '%', _message;

            _returnCode := 'U5209';
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Validate that the LC Cart Config name is unique when creating a new entry
    ---------------------------------------------------
    --
    If _mode = 'add' Then
        If Exists (Select * FROM t_lc_cart_configuration Where cart_config_name = _configName) Then
            _message := format('LC Cart Config already exists; cannot add a new config named %s', _configName);
            RAISE WARNING '%', _message;

            _returnCode := 'U5210';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If _mode = 'add' Then

        INSERT INTO t_lc_cart_configuration( cart_config_name,
                                             cart_id,
                                             description,
                                             autosampler,
                                             custom_valve_config,
                                             pumps,
                                             primary_injection_volume,
                                             primary_mobile_phases,
                                             primary_trap_column,
                                             primary_trap_flow_rate,
                                             primary_trap_time,
                                             primary_trap_mobile_phase,
                                             primary_analytical_column,
                                             primary_column_temperature,
                                             primary_analytical_flow_rate,
                                             primary_gradient,
                                             mass_spec_start_delay,
                                             upstream_injection_volume,
                                             upstream_mobile_phases,
                                             upstream_trap_column,
                                             upstream_trap_flow_rate,
                                             upstream_analytical_column,
                                             upstream_column_temperature,
                                             upstream_analytical_flow_rate,
                                             upstream_fractionation_profile,
                                             upstream_fractionation_details,
                                             cart_config_state,
                                             entered,
                                             entered_by,
                                             updated,
                                             updated_by )
        VALUES (
            _configName,
            _cartID,
            _description,
            _autosampler,
            _customValveConfig,
            _pumps,
            _primaryInjectionVolume,
            _primaryMobilePhases,
            _primaryTrapColumn,
            _primaryTrapFlowRate,
            _primaryTrapTime,
            _primaryTrapMobilePhase,
            _primaryAnalyticalColumn,
            _primaryColumnTemperature,
            _primaryAnalyticalFlowRate,
            _primaryGradient,
            _massSpecStartDelay,
            _upstreamInjectionVolume,
            _upstreamMobilePhases,
            _upstreamTrapColumn,
            _upstreamTrapFlowRate,
            _upstreamAnalyticalColumn,
            _upstreamColumnTemperature,
            _upstreamAnalyticalFlowRate,
            _upstreamFractionationProfile,
            _upstreamFractionationDetails,
            _state,
            CURRENT_TIMESTAMP,
            _entryUser,
            CURRENT_TIMESTAMP,
            _callingUser
        )
        RETURNING cart_config_id
        INTO _id;

    End If; -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If _mode = 'update' Then
        --
        UPDATE t_lc_cart_configuration
        SET cart_config_name = _configName,
            cart_id = _cartID,
            description = _description,
            autosampler = _autosampler,
            custom_valve_config = _customValveConfig,
            pumps = _pumps,
            primary_injection_volume = _primaryInjectionVolume,
            primary_mobile_phases = _primaryMobilePhases,
            primary_trap_column = _primaryTrapColumn,
            primary_trap_flow_rate = _primaryTrapFlowRate,
            primary_trap_time = _primaryTrapTime,
            primary_trap_mobile_phase = _primaryTrapMobilePhase,
            primary_analytical_column = _primaryAnalyticalColumn,
            primary_column_temperature = _primaryColumnTemperature,
            primary_analytical_flow_rate = _primaryAnalyticalFlowRate,
            primary_gradient = _primaryGradient,
            mass_spec_start_delay = _massSpecStartDelay,
            upstream_injection_volume = _upstreamInjectionVolume,
            upstream_mobile_phases = _upstreamMobilePhases,
            upstream_trap_column = _upstreamTrapColumn,
            upstream_trap_flow_rate = _upstreamTrapFlowRate,
            upstream_analytical_column = _upstreamAnalyticalColumn,
            upstream_column_temperature = _upstreamColumnTemperature,
            upstream_analytical_flow_rate = _upstreamAnalyticalFlowRate,
            upstream_fractionation_profile = _upstreamFractionationProfile,
            upstream_fractionation_details = _upstreamFractionationDetails,
            cart_config_state = _state,
            entered_by = _entryUser,
            updated = CURRENT_TIMESTAMP,
            updated_by = _callingUser
        WHERE cart_config_id = _id;

    End If; -- update mode

END
$$;

COMMENT ON PROCEDURE public.add_update_lc_cart_configuration IS 'AddUpdateLCCartConfiguration';
