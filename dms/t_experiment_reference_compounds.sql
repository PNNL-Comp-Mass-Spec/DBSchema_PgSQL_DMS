--
-- Name: t_experiment_reference_compounds; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_reference_compounds (
    exp_id integer NOT NULL,
    compound_id integer NOT NULL
);


ALTER TABLE public.t_experiment_reference_compounds OWNER TO d3l243;

--
-- Name: TABLE t_experiment_reference_compounds; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_reference_compounds TO readaccess;

