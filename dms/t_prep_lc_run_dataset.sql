--
-- Name: t_prep_lc_run_dataset; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_prep_lc_run_dataset (
    prep_lc_run_id integer NOT NULL,
    dataset_id integer NOT NULL
);


ALTER TABLE public.t_prep_lc_run_dataset OWNER TO d3l243;

--
-- Name: TABLE t_prep_lc_run_dataset; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_prep_lc_run_dataset TO readaccess;

