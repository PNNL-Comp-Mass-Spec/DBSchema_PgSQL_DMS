--
-- Name: trigfn_t_service_use_after_delete(); Type: FUNCTION; Schema: cc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cc.trigfn_t_service_use_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in cc.t_service_use_updates for the deleted service use entry
**
**  Auth:   mem
**  Date:   07/23/2025 mem - Initial release
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Add entries to cc.t_service_use_updates for each entry deleted from cc.t_service_use
    INSERT INTO cc.t_service_use_updates (
        service_use_entry_id,
        dataset_id,
        charge_code_change,
        service_type_change,
        entered_by
    )
    SELECT deleted.entry_id,
           deleted.dataset_id,
           format('%s -> ""', deleted.charge_code),
           format('%s -> 0', deleted.service_type_id),
           format('%s; %s', public.get_user_login_without_domain(''), COALESCE(deleted.ticket_number, 'Unknown ticket number'))
    FROM deleted
    ORDER BY deleted.entry_id;

    RETURN null;
END
$$;


ALTER FUNCTION cc.trigfn_t_service_use_after_delete() OWNER TO d3l243;

