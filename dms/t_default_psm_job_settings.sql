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
-- Name: TABLE t_default_psm_job_settings; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_default_psm_job_settings TO readaccess;

