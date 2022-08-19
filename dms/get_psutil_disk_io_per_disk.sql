--
-- Name: get_psutil_disk_io_per_disk(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_psutil_disk_io_per_disk(OUT read_bytes_sda double precision, OUT read_bytes_sdb double precision, OUT read_bytes_sdc double precision, OUT write_bytes_sda double precision, OUT write_bytes_sdb double precision, OUT write_bytes_sdc double precision) RETURNS record
    LANGUAGE plpython3u SECURITY DEFINER
    AS $$
from psutil import disk_io_counters
dc = disk_io_counters(perdisk=True)

sdaInfo = dc.get('sda')
sdbInfo = dc.get('sdb')
sdcInfo = dc.get('sdc')

sda_read_bytes = 0
sdb_read_bytes = 0
sdc_read_bytes = 0

sda_write_bytes = 0
sdb_write_bytes = 0
sdc_write_bytes = 0

if (sdaInfo is not None):
    sda_read_bytes  = sdaInfo.read_bytes
    sda_write_bytes = sdaInfo.write_bytes

if (sdbInfo is not None):
    sdb_read_bytes  = sdbInfo.read_bytes
    sdb_write_bytes = sdbInfo.write_bytes

if (sdcInfo is not None):
    sdc_read_bytes  = sdcInfo.read_bytes
    sdc_write_bytes = sdcInfo.write_bytes

return sda_read_bytes, sdb_read_bytes, sdc_read_bytes, sda_write_bytes, sdb_write_bytes, sdc_write_bytes
$$;


ALTER FUNCTION public.get_psutil_disk_io_per_disk(OUT read_bytes_sda double precision, OUT read_bytes_sdb double precision, OUT read_bytes_sdc double precision, OUT write_bytes_sda double precision, OUT write_bytes_sdb double precision, OUT write_bytes_sdc double precision) OWNER TO d3l243;

--
-- Name: FUNCTION get_psutil_disk_io_per_disk(OUT read_bytes_sda double precision, OUT read_bytes_sdb double precision, OUT read_bytes_sdc double precision, OUT write_bytes_sda double precision, OUT write_bytes_sdb double precision, OUT write_bytes_sdc double precision); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_psutil_disk_io_per_disk(OUT read_bytes_sda double precision, OUT read_bytes_sdb double precision, OUT read_bytes_sdc double precision, OUT write_bytes_sda double precision, OUT write_bytes_sdb double precision, OUT write_bytes_sdc double precision) IS 'created for pgwatch2';

--
-- Name: FUNCTION get_psutil_disk_io_per_disk(OUT read_bytes_sda double precision, OUT read_bytes_sdb double precision, OUT read_bytes_sdc double precision, OUT write_bytes_sda double precision, OUT write_bytes_sdb double precision, OUT write_bytes_sdc double precision); Type: ACL; Schema: public; Owner: d3l243
--

REVOKE ALL ON FUNCTION public.get_psutil_disk_io_per_disk(OUT read_bytes_sda double precision, OUT read_bytes_sdb double precision, OUT read_bytes_sdc double precision, OUT write_bytes_sda double precision, OUT write_bytes_sdb double precision, OUT write_bytes_sdc double precision) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_psutil_disk_io_per_disk(OUT read_bytes_sda double precision, OUT read_bytes_sdb double precision, OUT read_bytes_sdc double precision, OUT write_bytes_sda double precision, OUT write_bytes_sdb double precision, OUT write_bytes_sdc double precision) TO pgwatch2;

