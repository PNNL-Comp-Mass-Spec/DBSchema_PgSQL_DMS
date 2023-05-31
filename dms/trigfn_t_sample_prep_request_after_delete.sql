--
-- Name: trigfn_t_sample_prep_request_after_delete(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_sample_prep_request_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_sample_prep_request_updates for the deleted sample prep request
**
**  Auth:   mem
**  Date:   05/16/2008
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          08/06/2022 mem - Ported to PostgreSQL
**          05/31/2023 mem - Use format() for string concatenation
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Add entries to t_sample_prep_request_updates for each entry deleted from t_sample_prep_request
    INSERT INTO t_sample_prep_request_updates (
            request_id,
            system_account,
            beginning_state_ID,
            end_state_id)
    SELECT deleted.prep_request_id,
           format('%s; %s', public.get_user_login_without_domain(''), COALESCE(deleted.Request_Name, 'Unknown Request')),
           deleted.state_id,
           0 AS end_state_id
    FROM deleted
    ORDER BY deleted.prep_request_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_sample_prep_request_after_delete() OWNER TO d3l243;

