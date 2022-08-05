--
-- Name: trigfn_t_analysis_job_after_insert_or_update_validate(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_analysis_job_after_insert_or_update_validate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validates that the settings file name is valid
**      (it does not perform a tool-specific validation; it simply checks for a valid file name)
**
**      In addition, updates decontools_job_for_qc in T_Dataset
**
**  Auth:   mem
**          01/24/2013 mem - Initial version
**          11/25/2013 mem - Now updating decontools_job_for_qc in t_dataset
**          12/02/2013 mem - Refactored logic for updating decontools_job_for_qc to use multiple small queries instead of one large Update query
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _validateSettingsFile bool;
    _updateDeconToolsJob bool;
    _invalidSettingsFile text;
    _bestJobByDataset record;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; % (insert or update)', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If Not Exists (Select * From NEW) Then
        Return Null;
    End If;

    If TG_OP = 'INSERT' Then
        _validateSettingsFile := true;
    ElsIf  OLD.settings_file_name <> NEW.settings_file_name Then   -- Use <> since settings_file_name is never null
        _validateSettingsFile := true;
    Else
        _validateSettingsFile := false;
    End If;

    If _validateSettingsFile then
        _invalidSettingsFile := '';

        SELECT N.settings_file_Name
        INTO _invalidSettingsFile
        FROM NEW as N
             LEFT OUTER JOIN t_settings_files SF
               ON N.settings_file_Name = SF.file_name
        WHERE SF.file_name IS NULL;

        If FOUND Then
            RAISE EXCEPTION 'Invalid settings file: %', _invalidSettingsFile
                  USING HINT = 'Unrecognized settings file name (see trigger trigfn_t_analysis_job_after_insert_or_update_validate)';

            RETURN null;
        End If;
    End If;

    If TG_OP = 'INSERT' Then
        _updateDeconToolsJob := true;
    ElsIf OLD.job_state_id <> NEW.job_state_id Then   -- Use <> since job_state_id is never null
        _updateDeconToolsJob := true;
    Else
        _updateDeconToolsJob := false;
    End If;

    If _updateDeconToolsJob Then
        SELECT SourceQ.dataset_id, SourceQ.job
        INTO _bestJobByDataset
        FROM ( SELECT DS.dataset_id,
                      J.job AS Job,
                      Row_number() OVER ( PARTITION BY J.dataset_id ORDER BY J.job DESC ) AS JobRank
               FROM t_dataset DS
                    INNER JOIN t_analysis_job J
                      ON J.dataset_id = DS.dataset_id
                    INNER JOIN t_analysis_tool Tool
                      ON Tool.analysis_tool_id = J.analysis_tool_id AND
                         Tool.tool_base_name = 'Decon2LS'
                    INNER JOIN NEW as N
                      ON J.dataset_id = N.dataset_id
               WHERE J.job_state_id IN (2, 4)
             ) SourceQ
        WHERE SourceQ.jobRank = 1;

        If FOUND Then
            -- RAISE NOTICE '% trigger, % %, Store job % in t_dataset.decontools_job_for_qc for dataset_id %', TG_TABLE_NAME, TG_WHEN, TG_OP, _bestJobByDataset.job, _bestJobByDataset.dataset_id;

            UPDATE t_dataset
            SET decontools_job_for_qc = _bestJobByDataset.job
            WHERE t_dataset.dataset_id = _bestJobByDataset.dataset_id AND
                  t_dataset.decontools_job_for_qc IS DISTINCT FROM _bestJobByDataset.job;
        -- Else
            -- RAISE NOTICE '% trigger, % %, DeconTools job not found for dataset associated with job %', TG_TABLE_NAME, TG_WHEN, TG_OP, NEW.job;
        End If;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_analysis_job_after_insert_or_update_validate() OWNER TO d3l243;

