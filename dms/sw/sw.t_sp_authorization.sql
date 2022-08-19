--
-- Name: t_sp_authorization; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_sp_authorization (
    entry_id integer NOT NULL,
    procedure_name public.citext NOT NULL,
    login_name public.citext NOT NULL,
    host_name public.citext NOT NULL,
    host_ip public.citext DEFAULT ''::public.citext NOT NULL
);


ALTER TABLE sw.t_sp_authorization OWNER TO d3l243;

--
-- Name: t_sp_authorization_entry_id_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_sp_authorization ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_sp_authorization_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_sp_authorization pk_t_sp_authorization; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_sp_authorization
    ADD CONSTRAINT pk_t_sp_authorization PRIMARY KEY (entry_id);

--
-- Name: ix_t_sp_authorization_login_name; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_sp_authorization_login_name ON sw.t_sp_authorization USING btree (login_name);

--
-- Name: ix_t_sp_authorization_proc_name; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_sp_authorization_proc_name ON sw.t_sp_authorization USING btree (procedure_name);

--
-- Name: ix_t_sp_authorization_unique_procedure_login_host_ip; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_sp_authorization_unique_procedure_login_host_ip ON sw.t_sp_authorization USING btree (procedure_name, login_name, host_ip);

--
-- Name: ix_t_sp_authorization_unique_procedure_login_host_name; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_sp_authorization_unique_procedure_login_host_name ON sw.t_sp_authorization USING btree (procedure_name, login_name, host_name);

--
-- Name: TABLE t_sp_authorization; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_sp_authorization TO readaccess;

