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
-- Name: t_default_psm_job_parameters_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_default_psm_job_parameters ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_default_psm_job_parameters_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_default_psm_job_parameters pk_t_default_psm_job_parameters; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_default_psm_job_parameters
    ADD CONSTRAINT pk_t_default_psm_job_parameters PRIMARY KEY (job_type_name, tool_name, dyn_met_ox, stat_cys_alk, dyn_sty_phos);

--
-- Name: TABLE t_default_psm_job_parameters; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_default_psm_job_parameters TO readaccess;

