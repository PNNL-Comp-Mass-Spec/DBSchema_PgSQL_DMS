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
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> since charge_code_state is never null
    If OLD.charge_code_state <> NEW.charge_code_state Then
        UPDATE t_charge_code
        SET last_affected = CURRENT_TIMESTAMP
        WHERE t_charge_code.charge_code = NEW.charge_code;
    End If;

    UPDATE t_charge_code
    SET activation_state =
            charge_code_activation_state(
              NEW.deactivated,
              NEW.charge_code_state,
              NEW.usage_sample_prep,
              NEW.usage_requested_run)
    WHERE t_charge_code.charge_code = NEW.charge_code;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_charge_code_after_update() OWNER TO d3l243;

