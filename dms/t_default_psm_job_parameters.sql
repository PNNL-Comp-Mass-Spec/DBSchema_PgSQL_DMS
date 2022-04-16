--
-- Name: t_default_psm_job_parameters; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_default_psm_job_parameters (
    job_type_name public.citext NOT NULL,
    entry_id integer NOT NULL,
    tool_name public.citext NOT NULL,
    dyn_met_ox smallint NOT NULL,
    stat_cys_alk smallint NOT NULL,
    dyn_sty_phos smallint NOT NULL,
    parameter_file_name public.citext,
    enabled smallint NOT NULL
);


ALTER TABLE public.t_default_psm_job_parameters OWNER TO d3l243;

--
-- Name: TABLE t_default_psm_job_parameters; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_default_psm_job_parameters TO readaccess;

