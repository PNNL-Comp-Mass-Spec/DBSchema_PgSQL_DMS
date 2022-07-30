--
-- Name: trigfn_v_param_value_instead_of_update(); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.trigfn_v_param_value_instead_of_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Allows for updating the value or comment fields in view mc.v_param_value
**
**  Auth:   mem
**  Date:   01/24/2020 mem - Initial version
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, %', TG_TABLE_NAME, TG_WHEN, TG_LEVEL, TG_OP;

    IF TG_OP = 'UPDATE' THEN
        UPDATE mc.t_param_value
        SET value   = NEW.value,
            comment = NEW.comment
        WHERE entry_id = OLD.entry_id;

        RETURN NEW;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION mc.trigfn_v_param_value_instead_of_update() OWNER TO d3l243;
