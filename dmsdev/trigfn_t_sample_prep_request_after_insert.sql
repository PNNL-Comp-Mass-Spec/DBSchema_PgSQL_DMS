--
-- Name: trigfn_t_sample_prep_request_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_sample_prep_request_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_sample_prep_request_updates for the new sample prep request
**
**  Auth:   mem
**  Date:   05/16/2008
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          08/06/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_sample_prep_request_updates
        (
            request_id,
            system_account,
            beginning_state_ID,
            end_state_id
        )
    SELECT inserted.prep_request_id,
           public.get_user_login_without_domain(''),
           0,
           inserted.state_id
    FROM inserted
    ORDER BY inserted.prep_request_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_sample_prep_request_after_insert() OWNER TO d3l243;

