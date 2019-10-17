--
-- Name: t_mgrs; Type: TABLE; Schema: mc; Owner: d3l243
--

CREATE TABLE mc.t_mgrs (
    m_id integer NOT NULL,
    m_name public.citext NOT NULL,
    m_type_id integer NOT NULL,
    m_parm_value_changed smallint DEFAULT 1 NOT NULL,
    m_control_from_website smallint DEFAULT 0 NOT NULL,
    m_comment public.citext
);


ALTER TABLE mc.t_mgrs OWNER TO d3l243;

--
-- Name: t_mgrs_m_id_seq; Type: SEQUENCE; Schema: mc; Owner: d3l243
--

ALTER TABLE mc.t_mgrs ALTER COLUMN m_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mc.t_mgrs_m_id_seq
    START WITH 300
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_mgrs ix_t_mgrs; Type: CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_mgrs
    ADD CONSTRAINT ix_t_mgrs UNIQUE (m_id);

--
-- Name: t_mgrs pk_t_mgrs; Type: CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_mgrs
    ADD CONSTRAINT pk_t_mgrs PRIMARY KEY (m_id);

--
-- Name: ix_t_mgrs_m_name; Type: INDEX; Schema: mc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_mgrs_m_name ON mc.t_mgrs USING btree (m_name);

--
-- Name: t_mgrs fk_t_mgrs_t_mgr_types; Type: FK CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_mgrs
    ADD CONSTRAINT fk_t_mgrs_t_mgr_types FOREIGN KEY (m_type_id) REFERENCES mc.t_mgr_types(mt_type_id);

--
-- Name: TABLE t_mgrs; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.t_mgrs TO readaccess;
