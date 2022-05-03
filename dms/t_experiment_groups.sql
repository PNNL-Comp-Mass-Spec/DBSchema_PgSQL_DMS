--
-- Name: t_experiment_groups; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_groups (
    group_id integer NOT NULL,
    group_type public.citext NOT NULL,
    created timestamp without time zone NOT NULL,
    description public.citext,
    parent_exp_id integer NOT NULL,
    prep_lc_run_id integer,
    researcher public.citext,
    tab public.citext,
    member_count integer NOT NULL
);


ALTER TABLE public.t_experiment_groups OWNER TO d3l243;

--
-- Name: t_experiment_groups_group_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_experiment_groups ALTER COLUMN group_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_experiment_groups_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_experiment_groups pk_t_experiment_groups; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_groups
    ADD CONSTRAINT pk_t_experiment_groups PRIMARY KEY (group_id);

--
-- Name: ix_t_experiment_groups_parent_exp_id_group_id_include_type; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_experiment_groups_parent_exp_id_group_id_include_type ON public.t_experiment_groups USING btree (parent_exp_id, group_id) INCLUDE (group_type, created, description);

--
-- Name: TABLE t_experiment_groups; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_groups TO readaccess;

