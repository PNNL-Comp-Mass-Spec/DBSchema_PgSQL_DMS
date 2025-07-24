--
-- Name: trigfn_t_service_use_after_update(); Type: FUNCTION; Schema: cc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cc.trigfn_t_service_use_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in cc.t_service_use_updates for the updated service use entry
**
**  Auth:   mem
**  Date:   07/23/2025 mem - Initial release
**
*****************************************************/
DECLARE
    _username citext;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    _username := public.get_user_login_without_domain('');

    If OLD.charge_code     <> NEW.charge_code Or    -- Use <> since charge_code and service_type_id are never null
       OLD.service_type_id <> NEW.service_type_id
    Then
        INSERT INTO cc.t_service_use_updates (
            service_use_entry_id,
            dataset_id,
            charge_code_change,
            service_type_change,
            entered_by
        )
        SELECT NEW.entry_id,
               NEW.dataset_id,
               CASE WHEN OLD.charge_code <> NEW.charge_code
                    THEN format('%s -> %s', OLD.charge_code, NEW.charge_code)
                    ELSE NULL
               END,
               CASE WHEN OLD.service_type_id <> NEW.service_type_id
                    THEN format('%s -> %s', OLD.service_type_id, NEW.service_type_id)
                    ELSE NULL
               END,
               public.get_user_login_without_domain('');
    End If;

    RETURN null;
END
$$;


ALTER FUNCTION cc.trigfn_t_service_use_after_update() OWNER TO d3l243;

