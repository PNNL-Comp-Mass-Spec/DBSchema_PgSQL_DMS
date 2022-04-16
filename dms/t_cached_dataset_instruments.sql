--
-- Name: t_cached_dataset_instruments; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_dataset_instruments (
    dataset_id integer NOT NULL,
    instrument_id integer NOT NULL,
    instrument public.citext NOT NULL
);


ALTER TABLE public.t_cached_dataset_instruments OWNER TO d3l243;

--
-- Name: TABLE t_cached_dataset_instruments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_dataset_instruments TO readaccess;

