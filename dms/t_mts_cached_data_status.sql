--
-- Name: t_mts_cached_data_status; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_mts_cached_data_status (
    table_name public.citext NOT NULL,
    refresh_count integer NOT NULL,
    insert_count integer NOT NULL,
    update_count integer NOT NULL,
    delete_count integer NOT NULL,
    last_refreshed timestamp without time zone NOT NULL,
    last_refresh_minimum_id integer,
    last_full_refresh timestamp without time zone NOT NULL
);


ALTER TABLE public.t_mts_cached_data_status OWNER TO d3l243;

--
-- Name: TABLE t_mts_cached_data_status; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mts_cached_data_status TO readaccess;

