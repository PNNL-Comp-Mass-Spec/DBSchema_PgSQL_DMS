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
**
**  Auth:   mem
**  Date:   10/07/2008 mem
**          11/05/2012 mem - Now validating hms_auto_supersede
**          03/30/2015 mem - Now validating msgfplus_auto_centroid
**          08/06/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _affectedRowCount int;
    _queryResult1 record;
    _queryResult2 record;
    _message text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    SELECT Count(*)
    INTO _affectedRowCount
    FROM NEW;

    If _affectedRowCount > 1 Then
        RAISE EXCEPTION 'The "new" transition table for t_settings_files has more than one row'
              USING HINT = 'Assure that trigfn_t_settings_files_after_update is called via a FOR EACH ROW trigger';

        RETURN null;
    End If;

    -- Use IS DISTINCT FROM since hms_auto_supersede and msgfplus_auto_centroid can be null
    If NEW.hms_auto_supersede IS DISTINCT FROM OLD.hms_auto_supersede OR
       NEW.msgfplus_auto_centroid IS DISTINCT FROM OLD.msgfplus_auto_centroid Then

        -- Make sure a valid name (or null) was entered into the hms_auto_supersede and msgfplus_auto_centroid fields

        If Not NEW.hms_auto_supersede is null Then

            -- Make sure the settings file exists
            If Not Exists (SELECT * FROM t_settings_files WHERE file_name = NEW.hms_auto_supersede) Then
                RAISE EXCEPTION 'Settings file % is not defined in t_settings_files (referenced by hms_auto_supersede for settings_file_id % in t_settings_files)',
                      NEW.hms_auto_supersede, NEW.settings_file_id
                      USING HINT = 'See trigger trigfn_t_settings_files_after_update';

                RETURN null;
            End If;

            -- Make sure the settings file is valid for the given tool
            If Not Exists (
                SELECT *
                FROM NEW as N
                     INNER JOIN t_settings_files SF
                       ON N.hms_auto_supersede = SF.file_name AND
                          N.analysis_tool = SF.analysis_tool
                ) Then

                RAISE EXCEPTION 'Settings file % is not defined for tool % in t_settings_files (referenced by hms_auto_supersede for settings_file_id % in t_settings_files)',
                      NEW.hms_auto_supersede, NEW.analysis_tool, NEW.settings_file_id
                      USING HINT = 'See trigger trigfn_t_settings_files_after_update';

                RETURN null;
            End If;

        End If;

        If Not NEW.msgfplus_auto_centroid is null Then

            -- Make sure the settings file exists
            If Not Exists (SELECT * FROM t_settings_files WHERE file_name = NEW.msgfplus_auto_centroid) Then
                RAISE EXCEPTION 'Settings file % is not defined in t_settings_files (referenced by msgfplus_auto_centroid for settings_file_id % in t_settings_files)',
                      NEW.msgfplus_auto_centroid, NEW.settings_file_id
                      USING HINT = 'See trigger trigfn_t_settings_files_after_update';

                RETURN null;
            End If;

            -- Make sure the settings file is valid for the given tool
            If Not Exists (
                SELECT *
                FROM NEW as N
                     INNER JOIN t_settings_files SF
                       ON N.msgfplus_auto_centroid = SF.file_name AND
                          N.analysis_tool = SF.analysis_tool
                ) Then

                RAISE EXCEPTION 'Settings file % is not defined for tool % in t_settings_files (referenced by msgfplus_auto_centroid for settings_file_id % in t_settings_files)',
                      NEW.msgfplus_auto_centroid, NEW.analysis_tool, NEW.settings_file_id
                      USING HINT = 'See trigger trigfn_t_settings_files_after_update';

                RETURN null;
            End If;

        End If;
    End If;

    -- Use <> for analysis_tool and file_name since they can never be null
    -- In contrast, contents can be null
    If OLD.analysis_tool <> NEW.analysis_tool OR
       OLD.file_name <> NEW.file_name OR
       OLD.contents::text IS DISTINCT FROM NEW.contents::text Then

        INSERT INTO t_settings_files_xml_history (
                event_action, settings_file_id,
                analysis_tool, file_name,
                description, contents,
                entered, entered_by )
        SELECT 'Update' AS event_action, N.settings_file_id,
               N.analysis_tool, N.file_name,
               N.description, N.contents,
               CURRENT_TIMESTAMP, SESSION_USER
        FROM NEW as N;

    End if;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_settings_files_after_update() OWNER TO d3l243;

