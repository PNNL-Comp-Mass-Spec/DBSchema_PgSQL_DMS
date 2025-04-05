--
-- Name: t_mts_cached_data_status; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_mts_cached_data_status (
    table_name public.citext NOT NULL,
    refresh_count integer DEFAULT 0 NOT NULL,
    insert_count integer DEFAULT 0 NOT NULL,
    update_count integer DEFAULT 0 NOT NULL,
    delete_count integer DEFAULT 0 NOT NULL,
    last_refreshed timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_refresh_minimum_id integer,
    last_full_refresh timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_mts_cached_data_status OWNER TO d3l243;

--
-- Name: t_mts_cached_data_status pk_t_mts_cached_data_status; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_mts_cached_data_status
    ADD CONSTRAINT pk_t_mts_cached_data_status PRIMARY KEY (table_name);

ALTER TABLE public.t_mts_cached_data_status CLUSTER ON pk_t_mts_cached_data_status;

--
-- Name: TABLE t_mts_cached_data_status; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_mts_cached_data_status TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_mts_cached_data_status TO writeaccess;

