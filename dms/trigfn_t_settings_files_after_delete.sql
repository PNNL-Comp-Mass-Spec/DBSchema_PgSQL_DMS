--
-- Name: trigfn_t_settings_files_after_delete(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_settings_files_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Stores a copy of the deleted XML file in t_settings_files_xml_history
**
**  Auth:   mem
**  Date:   08/06/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_settings_files_xml_history (
            event_action, settings_file_id,
            analysis_tool, file_name,
            description, contents,
            entered, entered_by )
    SELECT 'Delete' AS event_action, settings_file_id,
           analysis_tool, file_name,
           description, contents,
           CURRENT_TIMESTAMP, SESSION_USER
    FROM deleted;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_settings_files_after_delete() OWNER TO d3l243;

