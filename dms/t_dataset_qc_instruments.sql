--
-- Name: t_dataset_qc_instruments; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_qc_instruments (
    in_name public.citext NOT NULL,
    instrument_id integer NOT NULL,
    last_updated timestamp without time zone NOT NULL
);


ALTER TABLE public.t_dataset_qc_instruments OWNER TO d3l243;

--
-- Name: TABLE t_dataset_qc_instruments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_qc_instruments TO readaccess;

