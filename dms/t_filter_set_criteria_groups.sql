--
-- Name: t_filter_set_criteria_groups; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_filter_set_criteria_groups (
    filter_criteria_group_id integer NOT NULL,
    filter_set_id integer NOT NULL
);


ALTER TABLE public.t_filter_set_criteria_groups OWNER TO d3l243;

--
-- Name: t_filter_set_criteria_groups pk_t_filter_set_criteria_groups; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_filter_set_criteria_groups
    ADD CONSTRAINT pk_t_filter_set_criteria_groups PRIMARY KEY (filter_criteria_group_id);

--
-- Name: t_filter_set_criteria_groups fk_t_filter_set_criteria_groups_t_filter_sets; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_filter_set_criteria_groups
    ADD CONSTRAINT fk_t_filter_set_criteria_groups_t_filter_sets FOREIGN KEY (filter_set_id) REFERENCES public.t_filter_sets(filter_set_id);

--
-- Name: TABLE t_filter_set_criteria_groups; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_filter_set_criteria_groups TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_filter_set_criteria_groups TO writeaccess;

