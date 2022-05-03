--
-- Name: t_default_psm_job_settings; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_default_psm_job_settings (
    tool_name public.citext NOT NULL,
    entry_id integer NOT NULL,
    job_type_name public.citext NOT NULL,
    stat_cys_alk smallint NOT NULL,
    dyn_sty_phos smallint NOT NULL,
    settings_file_name public.citext,
    enabled smallint NOT NULL
);


ALTER TABLE public.t_default_psm_job_settings OWNER TO d3l243;

--
-- Name: t_default_psm_job_settings_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_default_psm_job_settings ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_default_psm_job_settings_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_default_psm_job_settings pk_t_default_psm_job_settings; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_default_psm_job_settings
    ADD CONSTRAINT pk_t_default_psm_job_settings PRIMARY KEY (tool_name, job_type_name, stat_cys_alk, dyn_sty_phos);

--
-- Name: TABLE t_default_psm_job_settings; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_default_psm_job_settings TO readaccess;

