--
-- Name: t_event_target; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_event_target (
    id integer NOT NULL,
    name public.citext,
    target_table public.citext,
    target_id_column public.citext,
    target_state_column public.citext
);


ALTER TABLE pc.t_event_target OWNER TO d3l243;

--
-- Name: t_event_target pk_t_event_target; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_event_target
    ADD CONSTRAINT pk_t_event_target PRIMARY KEY (id);

--
-- Name: TABLE t_event_target; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_event_target TO readaccess;

