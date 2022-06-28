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

