--
-- Name: get_load_average_copy(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_load_average_copy(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision) RETURNS record
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'public', 'mc'
    AS $$
begin
    if random() < 0.02 then    /* clear the table on ca every 50th call not to be bigger than a couple of pages */
        truncate get_load_average_copy;
    end if;
    copy get_load_average_copy (load_1min, load_5min, load_15min, proc_count, last_procid) from '/proc/loadavg' with (format csv, delimiter ' ');
    select t.load_1min, t.load_5min, t.load_15min into load_1min, load_5min, load_15min from get_load_average_copy t order by created_on desc nulls last limit 1;
    return;
end;
$$;


ALTER FUNCTION public.get_load_average_copy(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision) OWNER TO d3l243;

--
-- Name: FUNCTION get_load_average_copy(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_load_average_copy(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision) IS 'created for pgwatch2';

--
-- Name: get_load_average_copy; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE UNLOGGED TABLE public.get_load_average_copy (
    load_1min double precision,
    load_5min double precision,
    load_15min double precision,
    proc_count text,
    last_procid integer,
    created_on timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.get_load_average_copy OWNER TO d3l243;

--
-- Name: FUNCTION get_load_average_copy(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_load_average_copy(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision) TO pgwatch2;

--
-- Name: TABLE get_load_average_copy; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.get_load_average_copy TO readaccess;

