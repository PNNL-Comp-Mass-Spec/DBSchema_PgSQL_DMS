--
-- Name: t_data_package_type; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_package_type (
    package_type public.citext NOT NULL,
    description public.citext
);


ALTER TABLE dpkg.t_data_package_type OWNER TO d3l243;

--
-- Name: t_data_package_type pk_t_data_package_type; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_type
    ADD CONSTRAINT pk_t_data_package_type PRIMARY KEY (package_type);

