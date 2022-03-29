--
-- Name: t_permissions_test_table; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_permissions_test_table (
    id integer NOT NULL,
    setting public.citext,
    value public.citext
);


ALTER TABLE ont.t_permissions_test_table OWNER TO d3l243;

--
-- Name: t_permissions_test_table pk_t_permissions_test_table; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_permissions_test_table
    ADD CONSTRAINT pk_t_permissions_test_table PRIMARY KEY (id);

