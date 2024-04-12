--
-- Name: t_archived_file_states; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_archived_file_states (
    archived_file_state_id integer NOT NULL,
    archived_file_state public.citext NOT NULL,
    description public.citext
);


ALTER TABLE pc.t_archived_file_states OWNER TO d3l243;

--
-- Name: t_archived_file_states_archived_file_state_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_archived_file_states ALTER COLUMN archived_file_state_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_archived_file_states_archived_file_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_archived_file_states pk_t_archived_file_states; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_archived_file_states
    ADD CONSTRAINT pk_t_archived_file_states PRIMARY KEY (archived_file_state_id);

ALTER TABLE pc.t_archived_file_states CLUSTER ON pk_t_archived_file_states;

--
-- Name: TABLE t_archived_file_states; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_archived_file_states TO readaccess;
GRANT SELECT ON TABLE pc.t_archived_file_states TO writeaccess;

