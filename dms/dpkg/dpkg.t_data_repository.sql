--
-- Name: t_data_repository; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_repository (
    repository_id integer NOT NULL,
    repository_name public.citext NOT NULL
);


ALTER TABLE dpkg.t_data_repository OWNER TO d3l243;

--
-- Name: t_data_repository_repository_id_seq; Type: SEQUENCE; Schema: dpkg; Owner: d3l243
--

ALTER TABLE dpkg.t_data_repository ALTER COLUMN repository_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME dpkg.t_data_repository_repository_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_data_repository pk_t_data_repository; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_repository
    ADD CONSTRAINT pk_t_data_repository PRIMARY KEY (repository_id);

ALTER TABLE dpkg.t_data_repository CLUSTER ON pk_t_data_repository;

--
-- Name: ix_t_data_repository_repository_name; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_data_repository_repository_name ON dpkg.t_data_repository USING btree (repository_name);

--
-- Name: TABLE t_data_repository; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_data_repository TO readaccess;
GRANT SELECT ON TABLE dpkg.t_data_repository TO writeaccess;

