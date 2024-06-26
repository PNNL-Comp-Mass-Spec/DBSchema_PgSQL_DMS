--
-- Name: get_results_directory_name(integer, text); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_results_directory_name(_job integer, _tag text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Determine the results directory name for the given job,
**      based on the tag, current timestamp, and job number
**
**  Arguments:
**    _job      Analysis job number
**    _tag      Three letter tag for the step tool, e.g. 'MSG'
**
**  Returns:
**      Directory name, e.g. 'MSG202406211840_Auto100000'
**
**  Example usage:
**      SELECT * FROM sw.get_results_directory_name(100000, 'MSG');
**
**  Auth:   grk
**  Date:   01/31/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          11/30/2022 mem - Ported to PostgreSQL
**          07/27/2023 mem - Remove local variable
**
*****************************************************/
DECLARE

BEGIN

    ---------------------------------------------------
    -- Construct job results directory name
    ---------------------------------------------------

    -- The auto-generated name has these components, all combined into one string:
    --  a) the 3-letter Results Tag,
    --  b) the current date, format yyyymmdd, for example 20221130 for 2022-11-30
    --  c) the current time, format hh24mi,   for example 1439     for 2:39 pm
    --  d) the text _Auto
    --  e) the Job number

    RETURN format('%s%s_Auto%s', _tag, to_char(CURRENT_TIMESTAMP, 'yyyymmddhh24mi'), _job);
END
$$;


ALTER FUNCTION sw.get_results_directory_name(_job integer, _tag text) OWNER TO d3l243;

--
-- Name: FUNCTION get_results_directory_name(_job integer, _tag text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_results_directory_name(_job integer, _tag text) IS 'CreateResultsDirectoryName or CreateResultsFolderName';

