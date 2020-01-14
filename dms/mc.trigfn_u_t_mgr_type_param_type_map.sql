--
-- Name: trigfn_u_t_mgr_type_param_type_map(); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE FUNCTION mc.trigfn_u_t_mgr_type_param_type_map() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates last_affected and entered_by if the parameter value changes
**
**  Auth:   mem
**  Date:   01/14/2020 mem - Initial version
**
*****************************************************/
BEGIN
    RAISE NOTICE '% trigger, % %, %', TG_TABLE_NAME, TG_WHEN, TG_LEVEL, TG_OP;

    -- Update the last_affected and entered_by columns in t_mgr_type_param_type_map
    UPDATE mc.t_mgr_type_param_type_map
    SET last_affected = CURRENT_TIMESTAMP,
        entered_by = SESSION_USER
    WHERE mc.t_mgr_type_param_type_map.mgr_type_id = NEW.mgr_type_id AND
          mc.t_mgr_type_param_type_map.param_type_id = NEW.param_type_id;

    RETURN null;
END
$$;


ALTER FUNCTION mc.trigfn_u_t_mgr_type_param_type_map() OWNER TO d3l243;
