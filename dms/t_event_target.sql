--
-- Name: t_event_target; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_event_target (
    target_type_id integer NOT NULL,
    target_type public.citext,
    target_table public.citext,
    target_id_column public.citext,
    target_state_column public.citext
);


ALTER TABLE public.t_event_target OWNER TO d3l243;

--
-- Name: t_event_target pk_t_event_target; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_event_target
    ADD CONSTRAINT pk_t_event_target PRIMARY KEY (target_type_id);

ALTER TABLE public.t_event_target CLUSTER ON pk_t_event_target;

--
-- Name: TABLE t_event_target; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_event_target TO readaccess;
GRANT SELECT ON TABLE public.t_event_target TO writeaccess;

