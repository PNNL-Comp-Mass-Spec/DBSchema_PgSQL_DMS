--
-- Name: t_default_psm_job_parameters; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_default_psm_job_parameters (
    entry_id integer NOT NULL,
    job_type_name public.citext NOT NULL,
    tool_name public.citext NOT NULL,
    dyn_met_ox smallint NOT NULL,
    stat_cys_alk smallint NOT NULL,
    dyn_sty_phos smallint NOT NULL,
    parameter_file_name public.citext,
    enabled smallint DEFAULT 1 NOT NULL
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
    ADD CONSTRAINT pk_t_default_psm_job_parameters PRIMARY KEY (entry_id);

--
-- Name: ix_t_default_psm_job_parameters_uniq_type_tool_met_ox_cys_alk; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_default_psm_job_parameters_uniq_type_tool_met_ox_cys_alk ON public.t_default_psm_job_parameters USING btree (job_type_name, tool_name, dyn_met_ox, stat_cys_alk, dyn_sty_phos);

--
-- Name: t_default_psm_job_parameters fk_t_default_psm_job_parameters_t_analysis_tool; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_default_psm_job_parameters
    ADD CONSTRAINT fk_t_default_psm_job_parameters_t_analysis_tool FOREIGN KEY (tool_name) REFERENCES public.t_analysis_tool(analysis_tool);

--
-- Name: t_default_psm_job_parameters fk_t_default_psm_job_parameters_t_default_psm_job_types; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_default_psm_job_parameters
    ADD CONSTRAINT fk_t_default_psm_job_parameters_t_default_psm_job_types FOREIGN KEY (job_type_name) REFERENCES public.t_default_psm_job_types(job_type_name);

--
-- Name: TABLE t_default_psm_job_parameters; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_default_psm_job_parameters TO readaccess;

