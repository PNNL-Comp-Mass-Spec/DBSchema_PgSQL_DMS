--
-- Name: t_default_psm_job_settings; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_default_psm_job_settings (
    entry_id integer NOT NULL,
    tool_name public.citext NOT NULL,
    job_type_name public.citext NOT NULL,
    stat_cys_alk smallint NOT NULL,
    dyn_sty_phos smallint NOT NULL,
    settings_file_name public.citext,
    enabled smallint DEFAULT 1 NOT NULL
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
    ADD CONSTRAINT pk_t_default_psm_job_settings PRIMARY KEY (entry_id);

--
-- Name: ix_t_default_psm_job_settings_uniq_tool_jobtype_cysalk_styphos; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_default_psm_job_settings_uniq_tool_jobtype_cysalk_styphos ON public.t_default_psm_job_settings USING btree (tool_name, job_type_name, stat_cys_alk, dyn_sty_phos);

--
-- Name: t_default_psm_job_settings trig_t_default_psm_job_settings_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_default_psm_job_settings_after_insert AFTER INSERT ON public.t_default_psm_job_settings FOR EACH ROW EXECUTE FUNCTION public.trigfn_t_default_psm_job_settings_after_insert_or_update();

--
-- Name: t_default_psm_job_settings trig_t_default_psm_job_settings_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_default_psm_job_settings_after_update AFTER UPDATE ON public.t_default_psm_job_settings FOR EACH ROW WHEN (((old.tool_name OPERATOR(public.<>) new.tool_name) OR (old.enabled <> new.enabled) OR (old.settings_file_name IS DISTINCT FROM new.settings_file_name))) EXECUTE FUNCTION public.trigfn_t_default_psm_job_settings_after_insert_or_update();

--
-- Name: t_default_psm_job_settings fk_t_default_psm_job_settings_t_analysis_tool; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_default_psm_job_settings
    ADD CONSTRAINT fk_t_default_psm_job_settings_t_analysis_tool FOREIGN KEY (tool_name) REFERENCES public.t_analysis_tool(analysis_tool);

--
-- Name: t_default_psm_job_settings fk_t_default_psm_job_settings_t_default_psm_job_types; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_default_psm_job_settings
    ADD CONSTRAINT fk_t_default_psm_job_settings_t_default_psm_job_types FOREIGN KEY (job_type_name) REFERENCES public.t_default_psm_job_types(job_type_name);

--
-- Name: TABLE t_default_psm_job_settings; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_default_psm_job_settings TO readaccess;
GRANT SELECT ON TABLE public.t_default_psm_job_settings TO writeaccess;

