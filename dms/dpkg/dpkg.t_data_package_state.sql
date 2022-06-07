--
-- Name: t_data_package_state; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_package_state (
    state_name public.citext NOT NULL,
    description public.citext
);


ALTER TABLE dpkg.t_data_package_state OWNER TO d3l243;

--
-- Name: t_data_package_state pk_t_data_package_state; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_state
    ADD CONSTRAINT pk_t_data_package_state PRIMARY KEY (state_name);

