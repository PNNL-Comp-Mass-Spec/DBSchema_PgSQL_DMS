--
-- Name: t_old_managers; Type: TABLE; Schema: mc; Owner: d3l243
--

CREATE TABLE mc.t_old_managers (
    mgr_id integer NOT NULL,
    mgr_name public.citext NOT NULL,
    mgr_type_id integer NOT NULL,
    param_value_changed smallint NOT NULL,
    control_from_website smallint NOT NULL,
    comment public.citext
);


ALTER TABLE mc.t_old_managers OWNER TO d3l243;

--
-- Name: t_old_managers pk_t_old_managers; Type: CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_old_managers
    ADD CONSTRAINT pk_t_old_managers PRIMARY KEY (mgr_id);

