--
-- Name: t_sp_authorization; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_sp_authorization (
    procedure_name public.citext NOT NULL,
    login_name public.citext NOT NULL,
    host_name public.citext NOT NULL
);


ALTER TABLE pc.t_sp_authorization OWNER TO d3l243;

--
-- Name: t_sp_authorization pk_t_sp_authorization; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_sp_authorization
    ADD CONSTRAINT pk_t_sp_authorization PRIMARY KEY (procedure_name, login_name, host_name);

--
-- Name: ix_t_sp_authorization_login_name; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_sp_authorization_login_name ON pc.t_sp_authorization USING btree (login_name);

--
-- Name: ix_t_sp_authorization_proc_name; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_sp_authorization_proc_name ON pc.t_sp_authorization USING btree (procedure_name);

