--
-- Name: trigfn_t_jobs_after_delete(); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.trigfn_t_jobs_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Raises an exception if all rows in t_jobs are deleted
**
**      Otherwise, adds entries to t_job_events for each deleted job
**
**  Auth:   mem
**  Date:   07/31/2022 mem - Ported to PostgreSQL
**          08/01/2022 mem - Prevent deleting all rows in the table
**          07/11/2023 mem - Use COUNT(job) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _newRowCount int;
    _deletedRowCount int;
    _message text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    SELECT COUNT(job)
    INTO _newRowCount
    FROM sw.t_jobs;

    SELECT COUNT(*)
    INTO _deletedRowCount
    FROM deleted;

    -- RAISE NOTICE 'New row count: %, deleted rows: %', _newRowCount, _deletedRowCount;

    If _deletedRowCount > 0 And _newRowCount = 0 Then
        _message := format('Cannot delete all %s rows in %s; use a WHERE clause to limit the affected rows (see trigger function %s)',
                           _deletedRowCount, 't_jobs', 'trigfn_t_jobs_after_delete');

        RAISE EXCEPTION '%', _message;
        RETURN null;
    End If;

    INSERT INTO sw.t_job_events (
        job,
        target_state,
        prev_target_state
    )
    SELECT deleted.job, 0 as New_State, deleted.State as Old_State
    FROM deleted
    ORDER BY deleted.job;

    RETURN null;
END
$$;


ALTER FUNCTION sw.trigfn_t_jobs_after_delete() OWNER TO d3l243;

