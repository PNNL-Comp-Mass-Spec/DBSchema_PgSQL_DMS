--
-- Name: t_properties; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_properties (
    property public.citext NOT NULL,
    value public.citext
);


ALTER TABLE dpkg.t_properties OWNER TO d3l243;

--
-- Name: t_properties pk_t_properties; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_properties
    ADD CONSTRAINT pk_t_properties PRIMARY KEY (property);

--
-- Name: TABLE t_properties; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_properties TO readaccess;
GRANT SELECT ON TABLE dpkg.t_properties TO writeaccess;

