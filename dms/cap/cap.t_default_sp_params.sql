--
-- Name: t_default_sp_params; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_default_sp_params (
    sp_name public.citext NOT NULL,
    param_name public.citext NOT NULL,
    param_value public.citext NOT NULL,
    description public.citext NOT NULL
);


ALTER TABLE cap.t_default_sp_params OWNER TO d3l243;

--
-- Name: t_default_sp_params pk_t_default_sp_params; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_default_sp_params
    ADD CONSTRAINT pk_t_default_sp_params PRIMARY KEY (sp_name, param_name);

