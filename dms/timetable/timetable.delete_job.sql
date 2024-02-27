--
-- Name: delete_job(text); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.delete_job(job_name text) RETURNS boolean
    LANGUAGE sql
    AS $_$
    WITH del_chain AS (DELETE FROM timetable.chain WHERE chain.chain_name = $1 RETURNING chain_id)
    SELECT EXISTS(SELECT 1 FROM del_chain)
$_$;


ALTER FUNCTION timetable.delete_job(job_name text) OWNER TO d3l243;

--
-- Name: FUNCTION delete_job(job_name text); Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON FUNCTION timetable.delete_job(job_name text) IS 'Delete the chain and its tasks from the system';

