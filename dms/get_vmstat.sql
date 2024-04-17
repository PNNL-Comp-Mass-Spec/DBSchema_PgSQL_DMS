--
-- Name: get_vmstat(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_vmstat(delay integer DEFAULT 1, OUT r integer, OUT b integer, OUT swpd bigint, OUT free bigint, OUT buff bigint, OUT cache bigint, OUT si bigint, OUT so bigint, OUT bi bigint, OUT bo bigint, OUT "in" integer, OUT cs integer, OUT us integer, OUT sy integer, OUT id integer, OUT wa integer, OUT st integer, OUT cpu_count integer, OUT load_1m real, OUT load_5m real, OUT load_15m real, OUT total_memory bigint) RETURNS record
    LANGUAGE plpython3u
    AS $$
    from os import cpu_count, popen
    unit = 1024  # 'vmstat' default block byte size

    cpu_count = cpu_count()
    vmstat_lines = popen('vmstat {} 2'.format(delay)).readlines()
    vm = [int(x) for x in vmstat_lines[-1].split()]
    # plpy.notice(vm)
    load_1m, load_5m, load_15m = None, None, None
    with open('/proc/loadavg', 'r') as f:
        la_line = f.readline()
        if la_line:
            splits = la_line.split()
            if len(splits) == 5:
                load_1m, load_5m, load_15m = splits[0], splits[1], splits[2]

    total_memory = None
    with open('/proc/meminfo', 'r') as f:
        mi_line = f.readline()
        splits = mi_line.split()
        # plpy.notice(splits)
        if len(splits) == 3:
            total_memory = int(splits[1]) * 1024

    return vm[0], vm[1], vm[2] * unit, vm[3] * unit, vm[4] * unit, vm[5] * unit, vm[6] * unit, vm[7] * unit, vm[8] * unit, \
        vm[9] * unit, vm[10], vm[11], vm[12], vm[13], vm[14], vm[15], vm[16], cpu_count, load_1m, load_5m, load_15m, total_memory
$$;


ALTER FUNCTION public.get_vmstat(delay integer, OUT r integer, OUT b integer, OUT swpd bigint, OUT free bigint, OUT buff bigint, OUT cache bigint, OUT si bigint, OUT so bigint, OUT bi bigint, OUT bo bigint, OUT "in" integer, OUT cs integer, OUT us integer, OUT sy integer, OUT id integer, OUT wa integer, OUT st integer, OUT cpu_count integer, OUT load_1m real, OUT load_5m real, OUT load_15m real, OUT total_memory bigint) OWNER TO d3l243;

--
-- Name: FUNCTION get_vmstat(delay integer, OUT r integer, OUT b integer, OUT swpd bigint, OUT free bigint, OUT buff bigint, OUT cache bigint, OUT si bigint, OUT so bigint, OUT bi bigint, OUT bo bigint, OUT "in" integer, OUT cs integer, OUT us integer, OUT sy integer, OUT id integer, OUT wa integer, OUT st integer, OUT cpu_count integer, OUT load_1m real, OUT load_5m real, OUT load_15m real, OUT total_memory bigint); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_vmstat(delay integer, OUT r integer, OUT b integer, OUT swpd bigint, OUT free bigint, OUT buff bigint, OUT cache bigint, OUT si bigint, OUT so bigint, OUT bi bigint, OUT bo bigint, OUT "in" integer, OUT cs integer, OUT us integer, OUT sy integer, OUT id integer, OUT wa integer, OUT st integer, OUT cpu_count integer, OUT load_1m real, OUT load_5m real, OUT load_15m real, OUT total_memory bigint) IS 'created for pgwatch2';

--
-- Name: FUNCTION get_vmstat(delay integer, OUT r integer, OUT b integer, OUT swpd bigint, OUT free bigint, OUT buff bigint, OUT cache bigint, OUT si bigint, OUT so bigint, OUT bi bigint, OUT bo bigint, OUT "in" integer, OUT cs integer, OUT us integer, OUT sy integer, OUT id integer, OUT wa integer, OUT st integer, OUT cpu_count integer, OUT load_1m real, OUT load_5m real, OUT load_15m real, OUT total_memory bigint); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_vmstat(delay integer, OUT r integer, OUT b integer, OUT swpd bigint, OUT free bigint, OUT buff bigint, OUT cache bigint, OUT si bigint, OUT so bigint, OUT bi bigint, OUT bo bigint, OUT "in" integer, OUT cs integer, OUT us integer, OUT sy integer, OUT id integer, OUT wa integer, OUT st integer, OUT cpu_count integer, OUT load_1m real, OUT load_5m real, OUT load_15m real, OUT total_memory bigint) TO pgwatch2;

