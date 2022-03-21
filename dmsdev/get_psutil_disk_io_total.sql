--
-- Name: get_psutil_disk_io_total(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_psutil_disk_io_total(OUT read_count double precision, OUT write_count double precision, OUT read_bytes double precision, OUT write_bytes double precision) RETURNS record
    LANGUAGE plpython3u
    AS $$
from psutil import disk_io_counters
dc = disk_io_counters(perdisk=False)
if dc:
    return dc.read_count, dc.write_count, dc.read_bytes, dc.write_bytes
else:
    return None, None, None, None
$$;


ALTER FUNCTION public.get_psutil_disk_io_total(OUT read_count double precision, OUT write_count double precision, OUT read_bytes double precision, OUT write_bytes double precision) OWNER TO d3l243;

--
-- Name: FUNCTION get_psutil_disk_io_total(OUT read_count double precision, OUT write_count double precision, OUT read_bytes double precision, OUT write_bytes double precision); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_psutil_disk_io_total(OUT read_count double precision, OUT write_count double precision, OUT read_bytes double precision, OUT write_bytes double precision) IS 'created for pgwatch2';

--
-- Name: FUNCTION get_psutil_disk_io_total(OUT read_count double precision, OUT write_count double precision, OUT read_bytes double precision, OUT write_bytes double precision); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_psutil_disk_io_total(OUT read_count double precision, OUT write_count double precision, OUT read_bytes double precision, OUT write_bytes double precision) TO pgwatch2;

