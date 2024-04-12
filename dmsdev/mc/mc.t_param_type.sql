--
-- Name: t_param_type; Type: TABLE; Schema: mc; Owner: d3l243
--

CREATE TABLE mc.t_param_type (
    param_type_id integer NOT NULL,
    param_name public.citext NOT NULL,
    picklist_name public.citext,
    comment public.citext
);


ALTER TABLE mc.t_param_type OWNER TO d3l243;

--
-- Name: t_param_type_param_type_id_seq; Type: SEQUENCE; Schema: mc; Owner: d3l243
--

ALTER TABLE mc.t_param_type ALTER COLUMN param_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mc.t_param_type_param_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_param_type pk_t_param_type; Type: CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_param_type
    ADD CONSTRAINT pk_t_param_type PRIMARY KEY (param_type_id);

--
-- Name: ix_t_param_type_param_name; Type: INDEX; Schema: mc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_param_type_param_name ON mc.t_param_type USING btree (param_name);

--
-- Name: TABLE t_param_type; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.t_param_type TO readaccess;
GRANT SELECT ON TABLE mc.t_param_type TO writeaccess;

