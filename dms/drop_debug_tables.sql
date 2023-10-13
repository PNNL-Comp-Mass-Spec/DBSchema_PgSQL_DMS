--
-- Name: drop_debug_tables(boolean, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.drop_debug_tables(IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Removes tables created for debugging purposes by the following procedures
**      - public.predefined_analysis_datasets
**      - cap.make_local_task_in_broker
**      - cap.move_tasks_to_main_tables
**      - sw.make_local_job_in_broker
**      - sw.move_jobs_to_main_tables
**
**  Arguments:
**    _infoOnly     When true, look for the tables, but do not delete them
**
**  Auth:   mem
**  Date:   10/12/2023 mem - Initial release
**          10/13/2023 mem - Also drop the t_debug_tmp tables created by make_local_job_in_broker and make_local_task_in_broker
**
*****************************************************/
DECLARE
    _tableCount int;
    _existingTables text;
    _tableInfo record;
    _sql text;
BEGIN
    _message := '';

    _infoOnly := Coalesce(_infoOnly, false);

    RAISE INFO '';

    CREATE TEMP TABLE T_Tmp_TablesToDelete (
        schemaname text,
        tablename text
    );

    -- Table T_Tmp_PredefinedAnalysisDatasets is created by predefined_analysis_datasets when _populateTempTable is true
    -- The T_Tmp_New_Task tables are created by cap.move_tasks_to_main_tables when _debugMode is true
    -- The T_Tmp_New_Job tables are created by sw.move_jobs_to_main_tables when _debugMode is true

    INSERT INTO T_Tmp_TablesToDelete (schemaname, tablename)
    SELECT schemaname, tablename
    FROM pg_catalog.pg_tables
    WHERE schemaname = 'public' AND tablename::citext IN ('T_Tmp_PredefinedAnalysisDatasets') OR
          schemaname = 'cap'    AND tablename::citext IN ('t_tmp_new_tasks',   't_tmp_new_task_steps',   't_tmp_new_task_step_dependencies',   't_tmp_new_task_parameters',
                                                          't_debug_tmp_tasks', 't_debug_tmp_task_steps', 't_debug_tmp_task_step_dependencies', 't_debug_tmp_task_parameters') OR
          schemaname = 'sw'     AND tablename::citext IN ('t_tmp_new_jobs',    't_tmp_new_job_steps',    't_tmp_new_job_step_dependencies',    't_tmp_new_job_parameters',
                                                          't_debug_tmp_jobs',  't_debug_tmp_job_steps',  't_debug_tmp_job_step_dependencies',  't_debug_tmp_job_parameters');

    GET DIAGNOSTICS _tableCount = ROW_COUNT;

    If _tableCount = 0 Then
        _message := 'Did not find any temp debug tables';
        RAISE INFO '%', _message;

        DROP TABLE T_Tmp_TablesToDelete;
        RETURN;
    End If;

    SELECT string_agg(format('%I.%I', schemaname, tablename), ', ' ORDER BY schemaname, tablename)
    INTO _existingTables
    FROM T_Tmp_TablesToDelete;

    If _infoOnly Then
        _message := format('Would delete the following temp debug %s:', public.check_plural(_tableCount, 'table', 'tables'));
        RAISE INFO '%', _message;

        _message := format('%s %s', _message, _existingTables);
    End If;

    FOR _tableInfo IN
        SELECT schemaname, tablename
        FROM T_Tmp_TablesToDelete
        ORDER BY schemaname, tablename
    LOOP
        If _infoOnly Then
            RAISE INFO '%', format('-  %I.%I', _tableInfo.schemaname, _tableInfo.tablename);
        Else
            _sql := format('DROP TABLE %I.%I', _tableInfo.schemaname, _tableInfo.tablename);
            EXECUTE _sql;
        End If;

    END LOOP;

    If Not _infoOnly Then
        _message := format('Deleted %s temp debug %s: %s', _tableCount, public.check_plural(_tableCount, 'table', 'tables'), _existingTables);
        RAISE INFO '%', _message;
    End If;

    DROP TABLE T_Tmp_TablesToDelete;
END
$$;


ALTER PROCEDURE public.drop_debug_tables(IN _infoonly boolean, INOUT _message text) OWNER TO d3l243;

