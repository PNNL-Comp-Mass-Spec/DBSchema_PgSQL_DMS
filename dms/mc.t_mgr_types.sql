--
-- Name: t_mgr_types; Type: TABLE; Schema: mc; Owner: d3l243
--

CREATE TABLE mc.t_mgr_types (
    mt_type_id integer NOT NULL,
    mt_type_name public.citext NOT NULL,
    mt_active smallint DEFAULT 1 NOT NULL
);


ALTER TABLE mc.t_mgr_types OWNER TO d3l243;

--
-- Name: t_mgr_types_mt_type_id_seq; Type: SEQUENCE; Schema: mc; Owner: d3l243
--

ALTER TABLE mc.t_mgr_types ALTER COLUMN mt_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mc.t_mgr_types_mt_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_mgr_types pk_t_mgr_types; Type: CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_mgr_types
    ADD CONSTRAINT pk_t_mgr_types PRIMARY KEY (mt_type_id);

--
-- Name: TABLE t_mgr_types; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.t_mgr_types TO readaccess;
