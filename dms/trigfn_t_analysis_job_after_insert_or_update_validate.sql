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
**      In addition, updates decontools_job_for_qc in t_dataset if the job state has changed
**
**  Auth:   mem
**          01/24/2013 mem - Initial version
**          11/25/2013 mem - Now updating decontools_job_for_qc in t_dataset
**          12/02/2013 mem - Refactored logic for updating decontools_job_for_qc to use multiple small queries instead of one large Update query
**          08/04/2022 mem - Ported to PostgreSQL
**          08/07/2022 mem - Use If Not Exists() when validating the settings file name
**                         - Reference the NEW and OLD variables directly instead of using transition tables (which contain every new or updated row, not just the current row)
**          04/27/2023 mem - Use boolean for data type name
**          05/22/2023 mem - Update whitespace
**
*****************************************************/
DECLARE
    _validateSettingsFile boolean;
    _updateDeconToolsJob boolean;
    _iteration int;
    _datasetID int;
    _bestJobByDataset record;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; % (insert or update)', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If TG_OP = 'INSERT' Then
        _validateSettingsFile := true;
    ElsIf OLD.settings_file_name <> NEW.settings_file_name Then   -- Use <> since settings_file_name is never null
        _validateSettingsFile := true;
    Else
        _validateSettingsFile := false;
    End If;

    If _validateSettingsFile Then
        If Not Exists (SELECT * FROM t_settings_files WHERE file_name = NEW.settings_file_name) Then
            RAISE EXCEPTION 'Settings file % is not defined in t_settings_files (job % in t_analysis_job)',
                  NEW.settings_file_name, NEW.job
                  USING HINT = 'See trigger function trigfn_t_analysis_job_after_insert_or_update_validate';

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
        FOR _iteration IN 1 .. 2
        LOOP

            If _iteration = 1 Then
                _datasetID := NEW.dataset_id;
            Else
                If Coalesce(OLD.dataset_ID, NEW.dataset_ID) = NEW.dataset_id Then
                    -- RAISE NOTICE '% trigger, % %, Dataset_ID is unchanged (or inserting a new row); exit the loop', TG_TABLE_NAME, TG_WHEN, TG_OP;
                    Exit;
                End If;

                _datasetID := OLD.dataset_id;
            End If;

            -- RAISE NOTICE '% trigger, % %, Update decontools_job_for_qc for dataset_id %', TG_TABLE_NAME, TG_WHEN, TG_OP, _datasetID;

            SELECT SourceQ.dataset_id, SourceQ.job
            INTO _bestJobByDataset
            FROM ( SELECT DS.dataset_id,
                          J.job AS Job,
                          Row_Number() OVER (PARTITION BY J.dataset_id ORDER BY J.job DESC) AS JobRank
                   FROM t_dataset DS
                        INNER JOIN t_analysis_job J
                          ON J.dataset_id = DS.dataset_id
                        INNER JOIN t_analysis_tool Tool
                          ON Tool.analysis_tool_id = J.analysis_tool_id AND
                             Tool.tool_base_name = 'Decon2LS'
                   WHERE J.dataset_id = _datasetID AND
                         J.job_state_id IN (2, 4)
                 ) SourceQ
            WHERE SourceQ.jobRank = 1;

            If FOUND Then
                -- RAISE NOTICE '% trigger, % %, Store job % in t_dataset.decontools_job_for_qc for dataset_id %', TG_TABLE_NAME, TG_WHEN, TG_OP, _bestJobByDataset.job, _bestJobByDataset.dataset_id;

                UPDATE t_dataset
                SET decontools_job_for_qc = _bestJobByDataset.job
                WHERE t_dataset.dataset_id = _bestJobByDataset.dataset_id AND
                      t_dataset.decontools_job_for_qc IS DISTINCT FROM _bestJobByDataset.job;
            -- Else
                -- RAISE NOTICE '% trigger, % %, DeconTools job not found for dataset associated with job %', TG_TABLE_NAME, TG_WHEN, TG_OP, inserted.job;
            End If;

        END LOOP;
    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_analysis_job_after_insert_or_update_validate() OWNER TO d3l243;

