--
-- Name: trigfn_t_experiment_plex_members_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_experiment_plex_members_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_experiment_plex_members_history for the updated exp_id to plex_exp_id mappings
**
**  Auth:   mem
**  Date:   11/28/2018 mem - Initial version
**          08/05/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> since exp_id is never null
    If OLD.exp_id <> NEW.exp_id Then

        -- Add entries to t_experiment_plex_members_history for each mapping changed in t_experiment_plex_members
        INSERT INTO t_experiment_plex_members_history
            (
                plex_exp_id,
                channel,
                exp_id,
                state,
                entered,
                entered_by
            )
        SELECT OLD.plex_exp_id,
               OLD.channel,
               OLD.exp_id,
               0 AS state,
               CURRENT_TIMESTAMP,
               SESSION_USER
        WHERE OLD.exp_id <> NEW.exp_id;

        INSERT INTO t_experiment_plex_members_history
            (
                plex_exp_id,
                channel,
                exp_id,
                state,
                entered,
                entered_by
            )
        SELECT NEW.plex_exp_id,
               NEW.channel,
               NEW.exp_id,
               1 AS state,
               CURRENT_TIMESTAMP,
               SESSION_USER
        WHERE OLD.exp_id <> NEW.exp_id;

    End If;

    If OLD.plex_exp_id <> NEW.plex_exp_id Then

        -- Add entries to t_experiment_plex_members_history for each mapping changed in t_experiment_plex_members
        INSERT INTO t_experiment_plex_members_history
            (
                plex_exp_id,
                channel,
                exp_id,
                state,
                entered,
                entered_by
            )
        SELECT OLD.plex_exp_id,
               OLD.channel,
               OLD.exp_id,
               0 AS state,
               CURRENT_TIMESTAMP,
               SESSION_USER;

        INSERT INTO t_experiment_plex_members_history
            (
                plex_exp_id,
                channel,
                exp_id,
                state,
                entered,
                entered_by
            )
        SELECT NEW.plex_exp_id,
               NEW.channel,
               NEW.exp_id,
               1 AS state,
               CURRENT_TIMESTAMP,
               SESSION_USER;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_experiment_plex_members_after_update() OWNER TO d3l243;

