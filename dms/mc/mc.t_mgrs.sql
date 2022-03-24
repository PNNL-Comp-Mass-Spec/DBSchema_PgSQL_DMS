--
-- Name: t_mgrs; Type: TABLE; Schema: mc; Owner: d3l243
--

CREATE TABLE mc.t_mgrs (
    mgr_id integer NOT NULL,
    mgr_name public.citext NOT NULL,
    mgr_type_id integer NOT NULL,
    param_value_changed smallint DEFAULT 1 NOT NULL,
    control_from_website smallint DEFAULT 0 NOT NULL,
    comment public.citext
);


ALTER TABLE mc.t_mgrs OWNER TO d3l243;

--
-- Name: t_mgrs_mgr_id_seq; Type: SEQUENCE; Schema: mc; Owner: d3l243
--

ALTER TABLE mc.t_mgrs ALTER COLUMN mgr_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mc.t_mgrs_mgr_id_seq
    START WITH 300
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_mgrs pk_t_mgrs; Type: CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_mgrs
    ADD CONSTRAINT pk_t_mgrs PRIMARY KEY (mgr_id);

--
-- Name: ix_t_mgrs_m_name; Type: INDEX; Schema: mc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_mgrs_m_name ON mc.t_mgrs USING btree (mgr_name);

--
-- Name: t_mgrs fk_t_mgrs_t_mgr_types; Type: FK CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_mgrs
    ADD CONSTRAINT fk_t_mgrs_t_mgr_types FOREIGN KEY (mgr_type_id) REFERENCES mc.t_mgr_types(mgr_type_id);

--
-- Name: TABLE t_mgrs; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.t_mgrs TO readaccess;

