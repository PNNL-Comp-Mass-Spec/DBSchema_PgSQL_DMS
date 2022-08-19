--
-- Name: t_experiment_plex_members; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_plex_members (
    plex_exp_id integer NOT NULL,
    channel smallint NOT NULL,
    exp_id integer NOT NULL,
    channel_type_id smallint NOT NULL,
    comment public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_experiment_plex_members OWNER TO d3l243;

--
-- Name: t_experiment_plex_members pk_t_experiment_plex_members; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_plex_members
    ADD CONSTRAINT pk_t_experiment_plex_members PRIMARY KEY (plex_exp_id, channel);

--
-- Name: ix_t_experiment_plex_members_exp_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiment_plex_members_exp_id ON public.t_experiment_plex_members USING btree (exp_id);

--
-- Name: t_experiment_plex_members trig_t_experiment_plex_members_after_delete_all; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_experiment_plex_members_after_delete_all AFTER DELETE ON public.t_experiment_plex_members REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_experiment_plex_members_after_delete_all();

--
-- Name: t_experiment_plex_members trig_t_experiment_plex_members_after_delete_row; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_experiment_plex_members_after_delete_row AFTER DELETE ON public.t_experiment_plex_members REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_experiment_plex_members_after_delete();

--
-- Name: t_experiment_plex_members trig_t_experiment_plex_members_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_experiment_plex_members_after_insert AFTER INSERT ON public.t_experiment_plex_members REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_experiment_plex_members_after_insert();

--
-- Name: t_experiment_plex_members trig_t_experiment_plex_members_after_update_all; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_experiment_plex_members_after_update_all AFTER UPDATE ON public.t_experiment_plex_members REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_experiment_plex_members_after_update_all();

--
-- Name: t_experiment_plex_members trig_t_experiment_plex_members_after_update_row; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_experiment_plex_members_after_update_row AFTER UPDATE ON public.t_experiment_plex_members FOR EACH ROW WHEN (((old.exp_id <> new.exp_id) OR (old.plex_exp_id <> new.plex_exp_id))) EXECUTE FUNCTION public.trigfn_t_experiment_plex_members_after_update();

--
-- Name: t_experiment_plex_members fk_t_experiment_plex_members_t_experiment_plex_channel_type; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_plex_members
    ADD CONSTRAINT fk_t_experiment_plex_members_t_experiment_plex_channel_type FOREIGN KEY (channel_type_id) REFERENCES public.t_experiment_plex_channel_type_name(channel_type_id);

--
-- Name: t_experiment_plex_members fk_t_experiment_plex_members_t_experiments_channel_exp; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_plex_members
    ADD CONSTRAINT fk_t_experiment_plex_members_t_experiments_channel_exp FOREIGN KEY (exp_id) REFERENCES public.t_experiments(exp_id);

--
-- Name: t_experiment_plex_members fk_t_experiment_plex_members_t_experiments_plex_exp; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_plex_members
    ADD CONSTRAINT fk_t_experiment_plex_members_t_experiments_plex_exp FOREIGN KEY (plex_exp_id) REFERENCES public.t_experiments(exp_id);

--
-- Name: TABLE t_experiment_plex_members; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_plex_members TO readaccess;
GRANT SELECT ON TABLE public.t_experiment_plex_members TO writeaccess;

