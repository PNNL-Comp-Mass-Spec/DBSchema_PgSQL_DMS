--
-- Name: t_analysis_status_monitor_params; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_status_monitor_params (
    processor_id integer NOT NULL,
    status_file_name_path public.citext,
    check_box_state smallint DEFAULT 0 NOT NULL,
    use_for_status_check smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.t_analysis_status_monitor_params OWNER TO d3l243;

--
-- Name: t_analysis_status_monitor_params pk_t_analysis_status_monitor_params; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_status_monitor_params
    ADD CONSTRAINT pk_t_analysis_status_monitor_params PRIMARY KEY (processor_id);

--
-- Name: t_analysis_status_monitor_params fk_t_analysis_status_monitor_params_t_analysis_job_processors; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_status_monitor_params
    ADD CONSTRAINT fk_t_analysis_status_monitor_params_t_analysis_job_processors FOREIGN KEY (processor_id) REFERENCES public.t_analysis_job_processors(processor_id) ON DELETE CASCADE;

--
-- Name: TABLE t_analysis_status_monitor_params; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_status_monitor_params TO readaccess;
GRANT SELECT ON TABLE public.t_analysis_status_monitor_params TO writeaccess;

