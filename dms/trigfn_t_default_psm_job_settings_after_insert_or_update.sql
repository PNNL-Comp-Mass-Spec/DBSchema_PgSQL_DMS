--
-- Name: trigfn_t_default_psm_job_settings_after_insert_or_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_default_psm_job_settings_after_insert_or_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validates that the settings file name is valid
**
**  Auth:   mem
**  Date:   11/13/2012 mem - Initial version
**          08/05/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If NEW.settings_file_name IS NULL Then
        If NEW.enabled = 0 Then
            -- Settings file name can be null when the default PSM job setting is not enabled
            RETURN null;
        End If;

        RAISE EXCEPTION 'Settings file name cannot be null for enabled default PSM job setting (entry_id % in t_default_psm_job_settings)', NEW.entry_id
              USING HINT = 'See trigger function trigfn_inserted_t_default_psm_job_settings_after_insert_or_update';

        RETURN null;
    End If;

    -- Make sure the settings file is valid
    If Not Exists (SELECT settings_file_id FROM t_settings_files WHERE file_name = NEW.settings_file_name) Then
        RAISE EXCEPTION 'Settings file % is not defined in t_settings_files (entry_id % in t_default_psm_job_settings)',
              NEW.settings_file_name, NEW.entry_id
              USING HINT = 'See trigger function trigfn_inserted_t_default_psm_job_settings_after_insert_or_update';

        RETURN null;
    End If;

    -- Make sure the settings file is valid for the given tool

    If Not Exists (
        SELECT SF.settings_file_id
        FROM t_settings_files SF
        WHERE SF.file_name = NEW.settings_file_name AND
              SF.analysis_tool = NEW.tool_name
        ) Then

        RAISE EXCEPTION 'Settings file % is not defined for tool % in t_settings_files (entry_id % in t_default_psm_job_settings)',
              NEW.settings_file_name, NEW.tool_name, NEW.entry_id
              USING HINT = 'See trigger function trigfn_inserted_t_default_psm_job_settings_after_insert_or_update';

        RETURN null;
    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_default_psm_job_settings_after_insert_or_update() OWNER TO d3l243;

