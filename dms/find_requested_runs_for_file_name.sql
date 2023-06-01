--
-- Name: find_requested_runs_for_file_name(public.citext); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.find_requested_runs_for_file_name(_filename public.citext) RETURNS TABLE(request public.citext, id integer, num_chars_matched integer, dataset_id integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**  Desc:
**      Returns list of active requested runs that match given file name
**      The entire request name must match the start of the file name
**
**  Auth:   grk
**  Date:   07/20/2012 grk - Initial release
**          06/17/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    RETURN QUERY
    SELECT  RR.request_name,
            RR.request_id,
            char_length(RR.request_name) AS num_chars_matched,
            RR.dataset_id
    FROM    t_requested_run RR
    WHERE   RR.state_name = 'Active'
            AND char_length(RR.request_name) <= char_length(_fileName)
            AND RR.request_name = SUBSTRING(_fileName, 1, char_length(RR.request_name))::citext
    ORDER BY char_length(request_name) DESC;

END
$$;


ALTER FUNCTION public.find_requested_runs_for_file_name(_filename public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION find_requested_runs_for_file_name(_filename public.citext); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.find_requested_runs_for_file_name(_filename public.citext) IS 'FindRequestedRunsForFileName';

