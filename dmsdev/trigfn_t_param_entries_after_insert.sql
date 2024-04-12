--
-- Name: trigfn_t_param_entries_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_param_entries_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates date_modified in t_param_files
**
**  Auth:   mem
**  Date:   10/12/2007 (Ticket:557)
**          08/05/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    UPDATE t_param_files
    SET date_modified = CURRENT_TIMESTAMP
    FROM inserted
    WHERE t_param_files.param_file_id = inserted.param_file_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_param_entries_after_insert() OWNER TO d3l243;

