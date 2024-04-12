--
-- Name: trigfn_t_data_analysis_request_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_data_analysis_request_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_data_analysis_request_updates for the new data analysis request
**
**  Auth:   mem
**  Date:   03/21/2022 mem - Initial version
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_data_analysis_request_updates (
        request_id,
        entered_by,
        old_state_id,
        new_state_id
    )
    SELECT inserted.request_id,
           public.get_user_login_without_domain(''),
           0,
           inserted.state
    FROM inserted
    ORDER BY inserted.request_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_data_analysis_request_after_insert() OWNER TO d3l243;

