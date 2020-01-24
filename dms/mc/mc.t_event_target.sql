--
-- Name: t_event_target; Type: TABLE; Schema: mc; Owner: d3l243
--

CREATE TABLE mc.t_event_target (
    id integer NOT NULL,
    name public.citext,
    target_table public.citext,
    target_id_column public.citext,
    target_state_column public.citext
);


ALTER TABLE mc.t_event_target OWNER TO d3l243;

--
-- Name: t_event_target pk_t_event_target; Type: CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_event_target
    ADD CONSTRAINT pk_t_event_target PRIMARY KEY (id);

--
-- Name: TABLE t_event_target; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.t_event_target TO readaccess;

