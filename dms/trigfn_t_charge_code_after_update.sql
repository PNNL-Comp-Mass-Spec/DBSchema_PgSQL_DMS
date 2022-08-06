--
-- Name: trigfn_t_charge_code_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_charge_code_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the last_affected and activation_state columns
**
**  Auth:   mem
**  Date:   06/05/2013 mem - Initial Version
**          06/07/2013 mem - Now updating activation_state
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If Not Exists (Select * From NEW) Then
        Return Null;
    End If;

    -- Use <> since charge_code_state is never null
    If OLD.charge_code_state <> NEW.charge_code_state Then
        UPDATE t_charge_code
        SET last_affected = CURRENT_TIMESTAMP
        FROM NEW as N
        WHERE t_charge_code.charge_code = N.charge_code;
    End If;

    -- Use <> for deactivated, charge_code_state, and activation_state since they are never null
    -- For the other comparisons, use IS DISTINCT FROM
    If OLD.deactivated <> NEW.deactivated OR
       OLD.charge_code_state <> NEW.charge_code_state OR
       OLD.usage_sample_prep IS DISTINCT FROM NEW.usage_sample_prep OR
       OLD.usage_requested_run IS DISTINCT FROM NEW.usage_requested_run OR
       OLD.activation_state <> NEW.activation_state Then

        UPDATE t_charge_code
        SET activation_state = charge_code_activation_state(
                  N.deactivated,
                  N.charge_code_state,
                  N.usage_sample_prep,
                  N.usage_requested_run)
        FROM NEW as N
        WHERE t_charge_code.charge_code = N.charge_code;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_charge_code_after_update() OWNER TO d3l243;

