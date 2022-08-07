--
-- Name: trigfn_t_sample_prep_request_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_sample_prep_request_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_sample_prep_request_updates for the updated sample prep request
**
**  Auth:   grk
**  Date:   01/01/2003
**          08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**          05/16/2008 mem - Fixed bug that was inserting the beginning_state_ID and end_state_id values backward
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          06/15/2021 mem - Do not insert a row if the state is unchanged and current user is msdadmin
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
    SELECT N.prep_request_id,
           public.get_user_login_without_domain(''),
           O.state_id,
           N.state_id
    FROM OLD as O INNER JOIN
         NEW as N ON O.prep_request_id = N.prep_request_id
    WHERE O.state_id <> N.state_id OR               -- Use <> since state_id is never null
          O.state_id = N.state_id AND
          Not public.get_user_login_without_domain('') IN ('postgres', 'msdadmin');

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_sample_prep_request_after_update() OWNER TO d3l243;

