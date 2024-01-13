--
-- Name: add_update_lc_cart_configuration(integer, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_lc_cart_configuration(IN _id integer, IN _configname text, IN _description text, IN _autosampler text, IN _customvalveconfig text, IN _pumps text, IN _primaryinjectionvolume text, IN _primarymobilephases text, IN _primarytrapcolumn text, IN _primarytrapflowrate text, IN _primarytraptime text, IN _primarytrapmobilephase text, IN _primaryanalyticalcolumn text, IN _primarycolumntemperature text, IN _primaryanalyticalflowrate text, IN _primarygradient text, IN _massspecstartdelay text, IN _upstreaminjectionvolume text, IN _upstreammobilephases text, IN _upstreamtrapcolumn text, IN _upstreamtrapflowrate text, IN _upstreamanalyticalcolumn text, IN _upstreamcolumntemperature text, IN _upstreamanalyticalflowrate text, IN _upstreamfractionationprofile text, IN _upstreamfractionationdetails text, IN _entryuser text DEFAULT ''::text, IN _state text DEFAULT 'Active'::text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing LC cart configuration entry
**
**  Arguments:
**    _id                           Cart config ID; column cart_config_id in t_lc_cart_configuration
**    _configName                   Cart config name
**    _description                  Description
**    _autosampler                  Autosampler name (empty string or null if no autosampler)
**    _customValveConfig            Custom valve config; 'none' or null if not applicable
**    _pumps                        Description of the LC pump(s) on the cart
**    _primaryInjectionVolume       Primary injection volume
**    _primaryMobilePhases          Primary mobile phases
**    _primaryTrapColumn            Primary trap column
**    _primaryTrapFlowRate          Primary trap column flow rate
**    _primaryTrapTime              Primary trap time
**    _primaryTrapMobilePhase       Primary trap mobile phase
**    _primaryAnalyticalColumn      Primary analytical column
**    _primaryColumnTemperature     Primary column temperature
**    _primaryAnalyticalFlowRate    Primary analytical flow rate
**    _primaryGradient              Primary gradient
**    _massSpecStartDelay           Mass spec start delay
**    _upstreamInjectionVolume      Upstream injection volume
**    _upstreamMobilePhases         Upstream mobile phases
**    _upstreamTrapColumn           Upstream trap column
**    _upstreamTrapFlowRate         Upstream trap flow rate
**    _upstreamAnalyticalColumn     Upstream analytical column
**    _upstreamColumnTemperature    Upstream column temperature
**    _upstreamAnalyticalFlowRate   Upstream analytical flow rate
**    _upstreamFractionationProfile Upstream fractionation profile
**    _upstreamFractionationDetails Upstream fractionation details
**    _entryUser                    User who entered the LC cart configuration entry; defaults to _callingUser if empty
**    _state                        State: 'Active', 'Inactive', 'Invalid', or 'Override' (see comments below)
**    _mode                         Mode: 'add' or 'update'
**    _message                      Status message
**    _returnCode                   Return code
**    _callingUser                  Username of the calling user
**
**  Auth:   mem
**  Date:   02/02/2017 mem - Initial version
**          02/22/2017 mem - Add several new parameters to match the updated columns in T_LC_Cart_Configuration
**          02/23/2017 mem - Validate the config name
**          02/24/2017 mem - Add parameters _primaryTrapTime and _primaryTrapMobilePhase
**                         - Allow changing state even if the Cart Config is associated with datasets
**          02/28/2017 mem - Remove parameter _cartName
**                         - Validate that _configName starts with a valid cart name
**          03/03/2017 mem - Add parameter _entryUser
**          09/17/2018 mem - Update cart config name error message
**          03/03/2021 mem - Update admin-required message
**          01/12/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _badCh text;
    _underscoreLoc int;
    _cartName citext;
    _cartID int := 0;
    _validatedName text;
    _existingName citext := '';
    _oldState citext := '';
    _ignoreDatasetChecks boolean := false;
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
    -- Validate the inputs
    ---------------------------------------------------

    _id          := Coalesce(_id, 0);
    _configName  := Trim(Coalesce(_configName, ''));
    _state       := Trim(Coalesce(_state, 'Active'));
    _entryUser   := Trim(Coalesce(_entryUser, ''));
    _callingUser := Trim(Coalesce(_callingUser, ''));
    _mode        := Trim(Lower(Coalesce(_mode, 'add')));

    If _configName = '' Then
        _message := format('LC cart configuration name must be specified');
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

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

    If Not _state::citext In ('Active', 'Inactive', 'Invalid', 'Override') Then
        _message := format('Cart config state must be Active, Inactive, or Invalid; %s is not allowed', _state);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    -- Assure that _state is properly capitalized
    _state := Upper(Left(_state, 1)) || Lower(substring(_state, 2));

    If _callingUser = '' And _entryUser <> '' Then
        _callingUser := _entryUser;
    ElsIf _callingUser = '' Then
        _callingUser := SESSION_USER;
    End If;

    If Not Exists (SELECT username FROM t_users WHERE username = _callingUser::citext) Then
        _callingUser := null;
    End If;

    If _entryUser = '' Then
        If Coalesce(_callingUser, '') <> '' Then
            _entryUser := _callingUser;
        Else
            _entryUser := SESSION_USER;
        End If;
    End If;

    If _state::citext = 'Override' And _mode <> 'update' Then
        _message := format('Cart config state must be Active, Inactive, or Invalid when mode is %s; %s is not allowed', _mode, _state);
    End If;

    ---------------------------------------------------
    -- Validate the cart configuration name
    -- First assure that it does not have invalid characters and is long enough
    ---------------------------------------------------

    _badCh := public.validate_chars(_configName, '');

    If _badCh <> '' Then
        If _badCh = 'space' Then
            _message := 'LC cart configuration name may not contain spaces';
        Else
            _message := format('LC cart configuration name may not contain the character(s) "%s"', _badCh);
        End If;

        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    If char_length(_configName) < 6 Then
        _message := format('LC cart configuration name must be at least 6 characters in length; currently %s characters', char_length(_configName));
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Assure that the config name starts with a valid cart name followed by an underscore, or starts with 'Unknown_'
    ---------------------------------------------------

    _underscoreLoc := Position('_' In _configName);

    If _underscoreLoc <=1 Then
        _message := 'Cart Config name must start with a valid LC cart name, followed by an underscore';
        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        RETURN;
    End If;

    _cartName := Substring(_configName, 1, _underscoreLoc - 1);

    If _cartName = 'Unknown' Then
        _cartName := 'No_Cart';
    End If;

    ---------------------------------------------------
    -- Resolve cart name to ID
    ---------------------------------------------------

    SELECT cart_id, cart_name
    INTO _cartID, _validatedName
    FROM  t_lc_cart
    WHERE cart_name = _cartName;

    If Not FOUND Then
        _message := format('Cart Config name must start with a valid LC cart name, followed by an underscore; unknown cart: %s', _cartName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5206';
        RETURN;
    End If;

    _cartName := _validatedName;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        -- Lookup the current name and state

        SELECT cart_config_name,
               cart_config_state,
               entered_by
        INTO _existingName, _oldState, _existingEntryUser
        FROM t_lc_cart_configuration
        WHERE cart_config_id = _id;

        If Not FOUND Then
            _message := format('Cannot update: cart config ID %s does not exist', _id);
            RAISE WARNING '%', _message;

            _returnCode := 'U5207';
            RETURN;
        End If;

        If _state::citext = 'Override' Then
            If Exists ( SELECT U.user_id
                        FROM t_users U
                             INNER JOIN t_user_operations_permissions OpsPerms
                               ON U.user_id = OpsPerms.user_id
                             INNER JOIN t_user_operations UserOps
                               ON OpsPerms.operation_id = UserOps.operation_id
                         WHERE U.username = _callingUser::citext AND
                               UserOps.operation = 'DMS_Infrastructure_Administration')
            Then
                -- Admin user is updating details for an LC cart config that is already associated with datasets
                -- Use the existing state
                _state := _oldState;
                _ignoreDatasetChecks := true;
            Else
                _message := format('Cart config state must be Active, Inactive, or Invalid; %s is not allowed', _state);
                RAISE WARNING '%', _message;

                _returnCode := 'U5208';
                RETURN;
            End If;
        End If;

        If _existingName <> _configName::citext Then

            SELECT cart_config_id
            INTO _conflictID
            FROM t_lc_cart_configuration
            WHERE cart_config_name = _configName::citext;

            If _conflictID > 0 Then
                _message := format('Cannot rename config from %s to %s because the new name is already in use by ID %s',
                                    _existingName, _configName, _conflictID);
                RAISE WARNING '%', _message;

                _returnCode := 'U5209';
                RETURN;
            End If;
        End If;

        If _entryUser = '' Then
            _entryUser := _existingEntryUser;
        End If;

        ---------------------------------------------------
        -- Only allow updating the state of cart config items that are associated with a dataset
        ---------------------------------------------------

        If Not _ignoreDatasetChecks And Exists (SELECT cart_config_id FROM t_dataset WHERE cart_config_id = _id) Then

            SELECT COUNT(dataset_id),
                   MAX(dataset_id)
            INTO _datasetCount, _maxDatasetID
            FROM t_dataset
            WHERE cart_config_id = _id;

            SELECT dataset
            INTO _datasetName
            FROM t_dataset
            WHERE dataset_id = _maxDatasetID;

            If _datasetCount = 1 Then
                _datasetDescription := format('dataset %s', _datasetName);
            Else
                _datasetDescription := format('%s datasets', _datasetCount);
            End If;

            If _state::citext <> _oldState Then
                UPDATE t_lc_cart_configuration
                SET cart_config_state = _state
                WHERE cart_config_id = _id;

                _message := format('Updated state to %s; any other changes were ignored because this cart config is associated with %s',
                                    _state, _datasetDescription);
                RETURN;
            End If;

            If _datasetCount = 1 then
                _message := format('LC cart config ID %s is associated with dataset %s; contact a DMS admin to update the configuration (using special state Override)',
                                   _id, _datasetName);
            Else
                _message := format('LC cart config ID %s is associated with %s, most recently %s; contact a DMS admin to update the configuration (using special state Override)',
                                   _id, _datasetDescription, _datasetName);
            End If;

            RAISE WARNING '%', _message;

            _returnCode := 'U5210';
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Validate that the LC cart config name is unique when creating a new entry
    ---------------------------------------------------

    If _mode = 'add' Then
        If Exists (SELECT cart_config_name FROM t_lc_cart_configuration WHERE cart_config_name = _configName::citext) Then
            _message := format('LC cart config already exists; cannot add a new config named %s', _configName);
            RAISE WARNING '%', _message;

            _returnCode := 'U5211';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        INSERT INTO t_lc_cart_configuration (
            cart_config_name,
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
            updated_by
        ) VALUES (
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

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_lc_cart_configuration
        SET cart_config_name               = _configName,
            cart_id                        = _cartID,
            description                    = _description,
            autosampler                    = _autosampler,
            custom_valve_config            = _customValveConfig,
            pumps                          = _pumps,
            primary_injection_volume       = _primaryInjectionVolume,
            primary_mobile_phases          = _primaryMobilePhases,
            primary_trap_column            = _primaryTrapColumn,
            primary_trap_flow_rate         = _primaryTrapFlowRate,
            primary_trap_time              = _primaryTrapTime,
            primary_trap_mobile_phase      = _primaryTrapMobilePhase,
            primary_analytical_column      = _primaryAnalyticalColumn,
            primary_column_temperature     = _primaryColumnTemperature,
            primary_analytical_flow_rate   = _primaryAnalyticalFlowRate,
            primary_gradient               = _primaryGradient,
            mass_spec_start_delay          = _massSpecStartDelay,
            upstream_injection_volume      = _upstreamInjectionVolume,
            upstream_mobile_phases         = _upstreamMobilePhases,
            upstream_trap_column           = _upstreamTrapColumn,
            upstream_trap_flow_rate        = _upstreamTrapFlowRate,
            upstream_analytical_column     = _upstreamAnalyticalColumn,
            upstream_column_temperature    = _upstreamColumnTemperature,
            upstream_analytical_flow_rate  = _upstreamAnalyticalFlowRate,
            upstream_fractionation_profile = _upstreamFractionationProfile,
            upstream_fractionation_details = _upstreamFractionationDetails,
            cart_config_state              = _state,
            entered_by                     = _entryUser,
            updated                        = CURRENT_TIMESTAMP,
            updated_by                     = _callingUser
        WHERE cart_config_id = _id;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_lc_cart_configuration(IN _id integer, IN _configname text, IN _description text, IN _autosampler text, IN _customvalveconfig text, IN _pumps text, IN _primaryinjectionvolume text, IN _primarymobilephases text, IN _primarytrapcolumn text, IN _primarytrapflowrate text, IN _primarytraptime text, IN _primarytrapmobilephase text, IN _primaryanalyticalcolumn text, IN _primarycolumntemperature text, IN _primaryanalyticalflowrate text, IN _primarygradient text, IN _massspecstartdelay text, IN _upstreaminjectionvolume text, IN _upstreammobilephases text, IN _upstreamtrapcolumn text, IN _upstreamtrapflowrate text, IN _upstreamanalyticalcolumn text, IN _upstreamcolumntemperature text, IN _upstreamanalyticalflowrate text, IN _upstreamfractionationprofile text, IN _upstreamfractionationdetails text, IN _entryuser text, IN _state text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_lc_cart_configuration(IN _id integer, IN _configname text, IN _description text, IN _autosampler text, IN _customvalveconfig text, IN _pumps text, IN _primaryinjectionvolume text, IN _primarymobilephases text, IN _primarytrapcolumn text, IN _primarytrapflowrate text, IN _primarytraptime text, IN _primarytrapmobilephase text, IN _primaryanalyticalcolumn text, IN _primarycolumntemperature text, IN _primaryanalyticalflowrate text, IN _primarygradient text, IN _massspecstartdelay text, IN _upstreaminjectionvolume text, IN _upstreammobilephases text, IN _upstreamtrapcolumn text, IN _upstreamtrapflowrate text, IN _upstreamanalyticalcolumn text, IN _upstreamcolumntemperature text, IN _upstreamanalyticalflowrate text, IN _upstreamfractionationprofile text, IN _upstreamfractionationdetails text, IN _entryuser text, IN _state text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_lc_cart_configuration(IN _id integer, IN _configname text, IN _description text, IN _autosampler text, IN _customvalveconfig text, IN _pumps text, IN _primaryinjectionvolume text, IN _primarymobilephases text, IN _primarytrapcolumn text, IN _primarytrapflowrate text, IN _primarytraptime text, IN _primarytrapmobilephase text, IN _primaryanalyticalcolumn text, IN _primarycolumntemperature text, IN _primaryanalyticalflowrate text, IN _primarygradient text, IN _massspecstartdelay text, IN _upstreaminjectionvolume text, IN _upstreammobilephases text, IN _upstreamtrapcolumn text, IN _upstreamtrapflowrate text, IN _upstreamanalyticalcolumn text, IN _upstreamcolumntemperature text, IN _upstreamanalyticalflowrate text, IN _upstreamfractionationprofile text, IN _upstreamfractionationdetails text, IN _entryuser text, IN _state text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateLCCartConfiguration';

