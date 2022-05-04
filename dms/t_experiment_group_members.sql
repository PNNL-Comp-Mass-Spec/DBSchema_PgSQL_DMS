--
-- Name: t_experiment_group_members; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_group_members (
    group_id integer NOT NULL,
    exp_id integer NOT NULL
);


ALTER TABLE public.t_experiment_group_members OWNER TO d3l243;

--
-- Name: t_experiment_group_members pk_t_experiment_group_members; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_group_members
    ADD CONSTRAINT pk_t_experiment_group_members PRIMARY KEY (group_id, exp_id);

--
-- Name: ix_t_experiment_group_members_exp_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiment_group_members_exp_id ON public.t_experiment_group_members USING btree (exp_id);

--
-- Name: ix_t_experiment_group_members_members_group_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiment_group_members_members_group_id ON public.t_experiment_group_members USING btree (group_id);

--
-- Name: t_experiment_group_members fk_t_experiment_group_members_t_experiment_groups; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_group_members
    ADD CONSTRAINT fk_t_experiment_group_members_t_experiment_groups FOREIGN KEY (group_id) REFERENCES public.t_experiment_groups(group_id);

--
-- Name: t_experiment_group_members fk_t_experiment_group_members_t_experiments; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_group_members
    ADD CONSTRAINT fk_t_experiment_group_members_t_experiments FOREIGN KEY (exp_id) REFERENCES public.t_experiments(exp_id);

--
-- Name: TABLE t_experiment_group_members; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_group_members TO readaccess;

