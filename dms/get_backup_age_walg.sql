--
-- Name: get_backup_age_walg(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_backup_age_walg(OUT retcode integer, OUT backup_age_seconds integer, OUT message text) RETURNS record
    LANGUAGE plpython3u
    SET statement_timeout TO '30s'
    AS $_$
import subprocess
retcode=1
backup_age_seconds=1000000
message=''

# get latest wal-g backup timestamp
walg_last_backup_cmd="""wal-g backup-list --json | jq -r '.[0].time'"""
p = subprocess.run(walg_last_backup_cmd, stdout=subprocess.PIPE, encoding='utf-8', shell=True)
if p.returncode != 0:
    # plpy.notice("p.stdout: " + str(p.stderr) + str(p.stderr))
    return p.returncode, backup_age_seconds, 'Not OK. Failed on wal-g backup-list call'

# plpy.notice("last_tz: " + last_tz)
last_tz=p.stdout.rstrip('\n\r')

# get seconds since last backup from WAL-G timestamp in format '2020-01-22T17:50:51Z'
try:
    plan = plpy.prepare("SELECT extract(epoch from now() - $1::timestamptz)::int AS backup_age_seconds;", ["text"])
    rv = plpy.execute(plan, [last_tz])
except Exception as e:
    return retcode, backup_age_seconds, 'Not OK. Failed to convert WAL-G backup timestamp to seconds'
else:
    backup_age_seconds = rv[0]["backup_age_seconds"]
    return 0, backup_age_seconds, 'OK. Last backup age in seconds: %s' % backup_age_seconds

$_$;


ALTER FUNCTION public.get_backup_age_walg(OUT retcode integer, OUT backup_age_seconds integer, OUT message text) OWNER TO d3l243;

--
-- Name: FUNCTION get_backup_age_walg(OUT retcode integer, OUT backup_age_seconds integer, OUT message text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_backup_age_walg(OUT retcode integer, OUT backup_age_seconds integer, OUT message text) IS 'created for pgwatch2';

--
-- Name: FUNCTION get_backup_age_walg(OUT retcode integer, OUT backup_age_seconds integer, OUT message text); Type: ACL; Schema: public; Owner: d3l243
--

REVOKE ALL ON FUNCTION public.get_backup_age_walg(OUT retcode integer, OUT backup_age_seconds integer, OUT message text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_backup_age_walg(OUT retcode integer, OUT backup_age_seconds integer, OUT message text) TO pgwatch2;

