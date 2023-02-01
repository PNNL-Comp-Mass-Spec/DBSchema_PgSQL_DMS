--
-- Name: trigfn_v_mgr_params_instead_of_update(); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.trigfn_v_mgr_params_instead_of_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Allows for updating the value or comment fields in view mc.v_mgr_params
**
**  Auth:   mem
**  Date:   03/15/2022 mem - Initial version
*           01/31/2023 mem - Use new column name in view
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    IF TG_OP = 'UPDATE' THEN
        UPDATE mc.t_param_value
        SET value   = NEW.parameter_value,
            comment = NEW.comment
        WHERE entry_id = OLD.entry_id;

        RETURN NEW;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION mc.trigfn_v_mgr_params_instead_of_update() OWNER TO d3l243;

