--
-- Name: t_pnnl_projects; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_pnnl_projects (
    project_number public.citext NOT NULL,
    project_num integer,
    setup_date timestamp(3) without time zone,
    resp_employee_id public.citext,
    resp_username public.citext,
    resp_hid public.citext,
    resp_cost_code public.citext,
    project_title public.citext,
    effective_date timestamp(3) without time zone,
    inactive_date timestamp(3) without time zone,
    deactivated boolean,
    deactivated_date timestamp(3) without time zone,
    invalid boolean,
    last_change_date timestamp(3) without time zone,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_pnnl_projects OWNER TO d3l243;

--
-- Name: t_pnnl_projects pk_t_pnnl_projects; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_pnnl_projects
    ADD CONSTRAINT pk_t_pnnl_projects PRIMARY KEY (project_number);

ALTER TABLE public.t_pnnl_projects CLUSTER ON pk_t_pnnl_projects;

--
-- Name: ix_t_pnnl_projects_project_num; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_pnnl_projects_project_num ON public.t_pnnl_projects USING btree (project_num);

--
-- Name: ix_t_pnnl_projects_resp_hid; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_pnnl_projects_resp_hid ON public.t_pnnl_projects USING btree (resp_hid);

--
-- Name: TABLE t_pnnl_projects; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_pnnl_projects TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_pnnl_projects TO writeaccess;

