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
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If NEW.parameter_file_name IS NULL Then
        If NEW.enabled = 0 Then
            -- Parameter file name can be null when the default PSM job parameter is not enabled
            RETURN null;
        End If;

        RAISE EXCEPTION 'Parameter file name cannot be null for enabled default PSM job parameter (entry_id % in t_default_psm_job_parameters)', NEW.entry_id
              USING HINT = 'See trigger function trigfn_t_default_psm_job_parameters_after_insert_or_update';

        RETURN null;
    End If;

    -- Make sure the parameter file is valid
    If Not Exists (SELECT param_file_id FROM t_param_files WHERE param_file_name = NEW.parameter_file_name) Then
        RAISE EXCEPTION 'Parameter file % is not defined in t_param_files (entry_id % in t_default_psm_job_parameters)',
              NEW.parameter_file_name, NEW.entry_id
              USING HINT = 'See trigger function trigfn_t_default_psm_job_parameters_after_insert_or_update';

        RETURN null;
    End If;

    -- Make sure the parameter file is valid for the given tool

    If Not Exists (
        SELECT PF.param_file_id
        FROM t_param_files PF
             INNER JOIN t_param_file_types PFT
               ON PFT.param_file_type_id = PF.param_file_type_id
             INNER JOIN t_analysis_tool Tool
               ON PFT.param_file_type_id = Tool.param_file_type_id AND
                  NEW.tool_name = Tool.analysis_tool
        WHERE PF.param_file_name = NEW.parameter_file_name
        ) Then

        RAISE EXCEPTION 'Parameter file % is not defined for tool % in t_param_files (entry_id % in t_default_psm_job_parameters)',
              NEW.parameter_file_name, NEW.tool_name, NEW.entry_id
              USING HINT = 'See trigger function trigfn_t_default_psm_job_parameters_after_insert_or_update';

        RETURN null;
    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_default_psm_job_parameters_after_insert_or_update() OWNER TO d3l243;

