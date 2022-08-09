--
-- Name: trigfn_t_settings_files_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_settings_files_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Stores a copy of the XML file in t_settings_files_xml_history
**      Also validates hms_auto_supersede and msgfplus_auto_centroid
**
**  Auth:   mem
**  Date:   10/07/2008 mem
**          11/05/2012 mem - Now validating hms_auto_supersede
**          03/30/2015 mem - Now validating msgfplus_auto_centroid
**          08/06/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Reference the OLD and NEW variables directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
DECLARE
    _queryResult1 record;
    _queryResult2 record;
    _message text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use IS DISTINCT FROM since hms_auto_supersede and msgfplus_auto_centroid can be null
    If OLD.hms_auto_supersede IS DISTINCT FROM NEW.hms_auto_supersede OR
       OLD.msgfplus_auto_centroid IS DISTINCT FROM NEW.msgfplus_auto_centroid Then

        -- Make sure a valid name (or null) was entered into the hms_auto_supersede and msgfplus_auto_centroid fields

        If Not NEW.hms_auto_supersede Is null Then

            -- Make sure the settings file exists
            If Not Exists (SELECT * FROM t_settings_files WHERE file_name = NEW.hms_auto_supersede) Then
                RAISE EXCEPTION 'Settings file % is not defined in t_settings_files (referenced by hms_auto_supersede for settings_file_id % in t_settings_files)',
                      NEW.hms_auto_supersede, NEW.settings_file_id
                      USING HINT = 'See trigger function trigfn_t_settings_files_after_update';

                RETURN null;
            End If;

            -- Make sure the settings file is valid for the given tool
            If Not Exists (
                SELECT *
                FROM t_settings_files
                WHERE file_name = NEW.hms_auto_supersede AND
                      analysis_tool = NEW.analysis_tool
                ) Then

                RAISE EXCEPTION 'Settings file % is not defined for tool % in t_settings_files (referenced by hms_auto_supersede for settings_file_id % in t_settings_files)',
                      NEW.hms_auto_supersede, NEW.analysis_tool, NEW.settings_file_id
                      USING HINT = 'See trigger function trigfn_t_settings_files_after_update';

                RETURN null;
            End If;

        End If;

        If Not NEW.msgfplus_auto_centroid Is null Then

            -- Make sure the settings file exists
            If Not Exists (SELECT * FROM t_settings_files WHERE file_name = NEW.msgfplus_auto_centroid) Then
                RAISE EXCEPTION 'Settings file % is not defined in t_settings_files (referenced by msgfplus_auto_centroid for settings_file_id % in t_settings_files)',
                      NEW.msgfplus_auto_centroid, NEW.settings_file_id
                      USING HINT = 'See trigger function trigfn_t_settings_files_after_update';

                RETURN null;
            End If;

            -- Make sure the settings file is valid for the given tool
            If Not Exists (
                SELECT *
                FROM t_settings_files
                WHERE file_name = NEW.msgfplus_auto_centroid AND
                      analysis_tool = NEW.analysis_tool
                ) Then

                RAISE EXCEPTION 'Settings file % is not defined for tool % in t_settings_files (referenced by msgfplus_auto_centroid for settings_file_id % in t_settings_files)',
                      NEW.msgfplus_auto_centroid, NEW.analysis_tool, NEW.settings_file_id
                      USING HINT = 'See trigger function trigfn_t_settings_files_after_update';

                RETURN null;
            End If;

        End If;
    End If;

    -- Use <> for analysis_tool and file_name since they are never null
    -- In contrast, contents can be null
    If OLD.analysis_tool <> NEW.analysis_tool OR
       OLD.file_name <> NEW.file_name OR
       OLD.contents::text IS DISTINCT FROM NEW.contents::text Then

        INSERT INTO t_settings_files_xml_history (
                event_action, settings_file_id,
                analysis_tool, file_name,
                description, contents,
                entered, entered_by )
        SELECT 'Update' AS event_action, NEW.settings_file_id,
               NEW.analysis_tool, NEW.file_name,
               NEW.description, NEW.contents,
               CURRENT_TIMESTAMP, SESSION_USER;

        UPDATE t_settings_files
        SET last_updated = CURRENT_TIMESTAMP
        WHERE settings_file_id = NEW.settings_file_id;

    End if;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_settings_files_after_update() OWNER TO d3l243;

