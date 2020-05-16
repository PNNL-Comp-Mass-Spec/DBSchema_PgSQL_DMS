--
-- Name: get_smart_health_per_device(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_smart_health_per_device(OUT device text, OUT retcode integer) RETURNS SETOF record
    LANGUAGE plpython3u
    AS $_$

import subprocess
ret_list = []

#disk_detect_cmd='smartctl --scan | cut -d " " -f3 | grep mega' # for Lenovo ServerRAID M1210
disk_detect_cmd='lsblk -io KNAME,TYPE | grep '' disk'' | cut -d " " -f1 | sort'
p = subprocess.run(disk_detect_cmd, stdout=subprocess.PIPE, encoding='utf-8', shell=True)
if p.returncode != 0:
    return ret_list
disks = p.stdout.splitlines()

for disk in disks:
    # health_cmd = 'smartctl -d $disk -a -q silent /dev/sda' % disk    # for Lenovo ServerRAID M1210 members
    health_cmd = 'smartctl  -a -q silent /dev/%s' % disk
    p = subprocess.run(health_cmd, stdout=subprocess.PIPE, encoding='utf-8', shell=True)
    ret_list.append((disk, p.returncode))

return ret_list

$_$;


ALTER FUNCTION public.get_smart_health_per_device(OUT device text, OUT retcode integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_smart_health_per_device(OUT device text, OUT retcode integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_smart_health_per_device(OUT device text, OUT retcode integer) IS 'created for pgwatch2';

--
-- Name: FUNCTION get_smart_health_per_device(OUT device text, OUT retcode integer); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_smart_health_per_device(OUT device text, OUT retcode integer) TO pgwatch2;

