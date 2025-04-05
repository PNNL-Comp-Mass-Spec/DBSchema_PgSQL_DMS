--
-- Name: t_sp_authorization; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_sp_authorization (
    entry_id integer NOT NULL,
    procedure_name public.citext NOT NULL,
    login_name public.citext NOT NULL,
    host_name public.citext NOT NULL,
    host_ip public.citext DEFAULT ''::public.citext NOT NULL
);


ALTER TABLE cap.t_sp_authorization OWNER TO d3l243;

--
-- Name: t_sp_authorization_entry_id_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_sp_authorization ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_sp_authorization_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_sp_authorization pk_t_sp_authorization; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_sp_authorization
    ADD CONSTRAINT pk_t_sp_authorization PRIMARY KEY (entry_id);

ALTER TABLE cap.t_sp_authorization CLUSTER ON pk_t_sp_authorization;

--
-- Name: ix_t_sp_authorization_login_name; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_sp_authorization_login_name ON cap.t_sp_authorization USING btree (login_name);

--
-- Name: ix_t_sp_authorization_proc_name; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_sp_authorization_proc_name ON cap.t_sp_authorization USING btree (procedure_name);

--
-- Name: ix_t_sp_authorization_unique_procedure_login_host_ip; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_sp_authorization_unique_procedure_login_host_ip ON cap.t_sp_authorization USING btree (procedure_name, login_name, host_ip);

--
-- Name: ix_t_sp_authorization_unique_procedure_login_host_name; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_sp_authorization_unique_procedure_login_host_name ON cap.t_sp_authorization USING btree (procedure_name, login_name, host_name);

--
-- Name: TABLE t_sp_authorization; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_sp_authorization TO readaccess;
GRANT SELECT ON TABLE cap.t_sp_authorization TO writeaccess;

