--
-- Name: t_biomaterial_tracking; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_biomaterial_tracking (
    biomaterial_id integer NOT NULL,
    experiment_count integer NOT NULL,
    dataset_count integer NOT NULL,
    job_count integer NOT NULL
);


ALTER TABLE public.t_biomaterial_tracking OWNER TO d3l243;

--
-- Name: TABLE t_biomaterial_tracking; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_biomaterial_tracking TO readaccess;

