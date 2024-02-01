--
-- Name: pg_backup_start_time(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.pg_backup_start_time() RETURNS timestamp with time zone
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      This is a placeholder function to replace the deprecated function pg_backup_start_time()
**      This function always returns null
**
**  Auth:   mem
**  Date:   01/31/2024 mem - Initial version
**
*****************************************************/
BEGIN
    RETURN null::timestamptz;
END;
$$;


ALTER FUNCTION public.pg_backup_start_time() OWNER TO d3l243;

