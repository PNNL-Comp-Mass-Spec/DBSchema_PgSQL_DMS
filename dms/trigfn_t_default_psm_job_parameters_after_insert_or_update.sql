--
-- Name: trigfn_t_default_psm_job_parameters_after_insert_or_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_default_psm_job_parameters_after_insert_or_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validates that the parameter file name is valid
**
**  Auth:   mem
**  Date:   11/13/2012 mem - Initial version
**          08/05/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _affectedRowCount int;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    SELECT Count(*)
    INTO _affectedRowCount
    FROM NEW;

    If _affectedRowCount > 1 Then
        RAISE EXCEPTION 'The "new" transition table for t_default_psm_job_parameters has more than one row'
              USING HINT = 'Assure that trigfn_t_default_psm_job_parameters_after_insert_or_update is called via a FOR EACH ROW trigger';

        RETURN null;
    End If;

    If TG_OP = 'UPDATE' Then
        If OLD.tool_name = NEW.tool_name AND                                            -- tool_name is never null
           OLD.enabled = NEW.enabled AND                                                -- enabled is never null
           OLD.parameter_file_name IS NOT DISTINCT FROM NEW.parameter_file_name Then    -- parameter_file_name could be null
            -- Tool name, enabled, and parameter file name are unchanged
            RETURN null;
        End If;
    End If;

    If NEW.parameter_file_name IS NULL Then
        If NEW.enabled = 0 Then
            -- Parameter file name can be null when the default PSM job parameter is not enabled
            RETURN null;
        End If;

        RAISE EXCEPTION 'Parameter file name cannot be null for enabled default PSM job parameter (entry_id % in t_default_psm_job_parameters)', NEW.entry_id
              USING HINT = 'See trigger trigfn_t_default_psm_job_parameters_after_insert_or_update';

        RETURN null;
    End If;

    -- Make sure the parameter file is valid
    If Not Exists (SELECT * FROM t_param_files WHERE param_file_name = NEW.parameter_file_name) Then
        RAISE EXCEPTION 'Parameter file % is not defined in t_param_files (entry_id % in t_default_psm_job_parameters)',
              NEW.parameter_file_name, NEW.entry_id
              USING HINT = 'See trigger trigfn_t_default_psm_job_parameters_after_insert_or_update';

        RETURN null;
    End If;

    -- Make sure the parameter file is valid for the given tool

    If Not Exists (
        SELECT *
        FROM NEW as N
             INNER JOIN t_param_files PF
               ON PF.param_file_name= N.parameter_file_name
             INNER JOIN t_param_file_types PFT
               ON PFT.param_file_type_id = PF.param_file_type_id
             INNER JOIN t_analysis_tool Tool
               ON PFT.param_file_type_id = Tool.param_file_type_id AND
                  N.tool_name = Tool.analysis_tool
        ) Then

        RAISE EXCEPTION 'Parameter file % is not defined for tool % in t_param_files (entry_id % in t_default_psm_job_parameters)',
              NEW.parameter_file_name, NEW.tool_name, NEW.entry_id
              USING HINT = 'See trigger trigfn_t_default_psm_job_parameters_after_insert_or_update';

        RETURN null;
    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_default_psm_job_parameters_after_insert_or_update() OWNER TO d3l243;

