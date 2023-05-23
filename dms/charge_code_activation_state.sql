--
-- Name: charge_code_activation_state(text, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.charge_code_activation_state(_deactivated text, _chargecodestate integer, _usagesampleprep integer, _usagerequestedrun integer) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Computes the Activation_State for a charge code, given the specified properties
**
**          This function is used by trigger trig_u_Charge_Code to auto-define Activation_State in T_Charge_Code
**
**  Arguments:
**    _deactivated          N or Y; assumed to never be null since not null in T_Charge_State
**    _chargeCodeState      Charge code state, as defined in T_Charge_Code_State
**    _usageSamplePrep      Number of sample prep requests that use this charge code
**    _usageRequestedRun    Number of requested runs that use this charge code
**
**  Auth:   mem
**  Date:   06/07/2013 mem - Initial release
**          11/19/2013 mem - Bug fix assigning ActivationState for Inactive, old work packages
**          06/17/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _activationState int2;
    _usageCount int;
BEGIN
    _deactivated := Upper(_deactivated);
    _chargeCodeState := Coalesce(_chargeCodeState, 0);
    _usageCount := Coalesce(_usageSamplePrep, 0) + Coalesce(_usageRequestedRun, 0);

    _activationState :=
        CASE
          WHEN _deactivated = 'N' AND _chargeCodeState >= 2 THEN 0                            -- Active
          WHEN _deactivated = 'N' AND _chargeCodeState  = 1 And _usageCount > 0 THEN 0        -- Active
          WHEN _deactivated = 'N' AND _chargeCodeState  = 1 And _usageCount = 0 THEN 1        -- Active, unused
          WHEN _deactivated = 'N' AND _chargeCodeState  = 0 THEN 2                            -- Active, old

          WHEN _deactivated <> 'N' AND _chargeCodeState >= 2 THEN 3                           -- Inactive, used
          WHEN _deactivated <> 'N' AND _chargeCodeState IN (0, 1) And _usageCount > 0 THEN 3  -- Inactive, used
          WHEN _deactivated <> 'N' AND _chargeCodeState IN (0, 1) And _usageCount = 0 THEN 4  -- Inactive, unused
          ELSE 5                                                                              -- Inactive, old
        END;

    RETURN _activationState;
END
$$;


ALTER FUNCTION public.charge_code_activation_state(_deactivated text, _chargecodestate integer, _usagesampleprep integer, _usagerequestedrun integer) OWNER TO d3l243;

--
-- Name: FUNCTION charge_code_activation_state(_deactivated text, _chargecodestate integer, _usagesampleprep integer, _usagerequestedrun integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.charge_code_activation_state(_deactivated text, _chargecodestate integer, _usagesampleprep integer, _usagerequestedrun integer) IS 'ChargeCodeActivationState';

