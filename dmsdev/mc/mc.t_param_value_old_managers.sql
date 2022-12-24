--
-- Name: t_param_value_old_managers; Type: TABLE; Schema: mc; Owner: d3l243
--

CREATE TABLE mc.t_param_value_old_managers (
    entry_id integer NOT NULL,
    type_id integer NOT NULL,
    value public.citext NOT NULL,
    mgr_id integer NOT NULL,
    comment public.citext,
    last_affected timestamp without time zone,
    entered_by public.citext
);


ALTER TABLE mc.t_param_value_old_managers OWNER TO d3l243;

--
-- Name: t_param_value_old_managers pk_t_param_value_old_managers; Type: CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_param_value_old_managers
    ADD CONSTRAINT pk_t_param_value_old_managers PRIMARY KEY (entry_id);

