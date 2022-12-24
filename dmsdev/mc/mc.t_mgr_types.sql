--
-- Name: t_mgr_types; Type: TABLE; Schema: mc; Owner: d3l243
--

CREATE TABLE mc.t_mgr_types (
    mgr_type_id integer NOT NULL,
    mgr_type_name public.citext NOT NULL,
    mgr_type_active smallint DEFAULT 1 NOT NULL
);


ALTER TABLE mc.t_mgr_types OWNER TO d3l243;

--
-- Name: t_mgr_types_mgr_type_id_seq; Type: SEQUENCE; Schema: mc; Owner: d3l243
--

ALTER TABLE mc.t_mgr_types ALTER COLUMN mgr_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mc.t_mgr_types_mgr_type_id_seq
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
    ADD CONSTRAINT pk_t_mgr_types PRIMARY KEY (mgr_type_id);

