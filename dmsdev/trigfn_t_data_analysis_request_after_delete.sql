--
-- Name: trigfn_t_data_analysis_request_after_delete(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_data_analysis_request_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_data_analysis_request_updates for the deleted data analysis request
**
**  Auth:   mem
**  Date:   03/21/2022 mem - Initial version
**          08/04/2022 mem - Ported to PostgreSQL
**          05/31/2023 mem - Use format() for string concatenation
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Add entries to t_data_analysis_request_updates for each entry deleted from t_data_analysis_request
    INSERT INTO t_data_analysis_request_updates (
        request_id,
        entered_by,
        old_state_id,
        new_state_id
    )
    SELECT deleted.request_id,
           format('%s; %s', public.get_user_login_without_domain(''), COALESCE(deleted.Request_Name, 'Unknown Request')),
           deleted.state,
           0 AS New_State_ID
    FROM deleted
    ORDER BY deleted.request_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_data_analysis_request_after_delete() OWNER TO d3l243;

