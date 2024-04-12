--
-- Name: get_backup_age_pgbackrest(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_backup_age_pgbackrest(OUT retcode integer, OUT backup_age_seconds integer, OUT message text) RETURNS record
    LANGUAGE plpython3u
    SET statement_timeout TO '30s'
    AS $_$
import subprocess
retcode=1
backup_age_seconds=1000000
message=''

# get latest wal-g backup timestamp (for any stanza):
# walg_last_backup_cmd="""pgbackrest --output=json info | jq '.[0] | .backup[-1] | .timestamp.stop'"""

# get latest wal-g backup timestamp (for specific stanza):
walg_last_backup_cmd="""pgbackrest --output=json info | jq '.[] | select( .name == "dmsprod2") | .backup[-1] | .timestamp.stop'"""

p = subprocess.run(walg_last_backup_cmd, stdout=subprocess.PIPE, encoding='utf-8', shell=True)
if p.returncode != 0:
    # plpy.notice("p.stdout: " + str(p.stderr) + str(p.stderr))
    return p.returncode, backup_age_seconds, 'Not OK. Failed on "pgbackrest info" call'

last_backup_stop_epoch=p.stdout.rstrip('\n\r')

try:
    plan = plpy.prepare("SELECT (extract(epoch from now()) - $1)::int8 AS backup_age_seconds;", ["int8"])
    rv = plpy.execute(plan, [last_backup_stop_epoch])
except Exception as e:
    return retcode, backup_age_seconds, 'Not OK. Failed to extract seconds difference via Postgres'
else:
    backup_age_seconds = rv[0]["backup_age_seconds"]
    return 0, backup_age_seconds, 'OK. Last backup age in seconds: %s' % backup_age_seconds

$_$;


ALTER FUNCTION public.get_backup_age_pgbackrest(OUT retcode integer, OUT backup_age_seconds integer, OUT message text) OWNER TO d3l243;

--
-- Name: FUNCTION get_backup_age_pgbackrest(OUT retcode integer, OUT backup_age_seconds integer, OUT message text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_backup_age_pgbackrest(OUT retcode integer, OUT backup_age_seconds integer, OUT message text) IS 'created for pgwatch2';

--
-- Name: FUNCTION get_backup_age_pgbackrest(OUT retcode integer, OUT backup_age_seconds integer, OUT message text); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_backup_age_pgbackrest(OUT retcode integer, OUT backup_age_seconds integer, OUT message text) TO pgwatch2;

