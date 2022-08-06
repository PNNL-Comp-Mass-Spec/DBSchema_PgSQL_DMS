--
-- Name: trigfn_t_experiment_plex_members_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_experiment_plex_members_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_experiment_plex_members_history for the new exp_id to plex_exp_id mapping
**
**  Auth:   mem
**  Date:   11/28/2018 mem - Initial version
**          08/05/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Add entries to t_experiment_plex_members_history for each mapping added to t_experiment_plex_members
    INSERT INTO t_experiment_plex_members_history
        (
            plex_exp_id,
            channel,
            exp_id,
            state,
            entered,
            entered_by
        )
    SELECT  plex_exp_id,
            channel,
            exp_id,
            1 As state,
            CURRENT_TIMESTAMP,
            SESSION_USER
    FROM inserted
    ORDER BY plex_exp_id, channel;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_experiment_plex_members_after_insert() OWNER TO d3l243;

