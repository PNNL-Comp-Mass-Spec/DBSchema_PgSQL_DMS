--
-- Name: t_scripts; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_scripts (
    script_id integer NOT NULL,
    script public.citext NOT NULL,
    description public.citext,
    enabled character(1) DEFAULT 'N'::bpchar NOT NULL,
    results_tag public.citext,
    contents xml,
    parameters xml,
    fields xml,
    backfill_to_dms smallint DEFAULT 0 NOT NULL,
    pipeline_job_enabled smallint DEFAULT 0 NOT NULL,
    pipeline_mac_job_enabled smallint DEFAULT 0 NOT NULL
);


ALTER TABLE sw.t_scripts OWNER TO d3l243;

--
-- Name: t_scripts pk_t_scripts; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_scripts
    ADD CONSTRAINT pk_t_scripts PRIMARY KEY (script_id);

--
-- Name: ix_t_scripts; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_scripts ON sw.t_scripts USING btree (script);

--
-- Name: t_scripts trig_t_scripts_after_delete; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_scripts_after_delete AFTER DELETE ON sw.t_scripts REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION sw.trigfn_t_scripts_after_delete();

--
-- Name: t_scripts trig_t_scripts_after_insert; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_scripts_after_insert AFTER INSERT ON sw.t_scripts REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION sw.trigfn_t_scripts_after_insert();

--
-- Name: t_scripts trig_t_scripts_after_update; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_scripts_after_update AFTER UPDATE ON sw.t_scripts FOR EACH ROW WHEN (((old.script OPERATOR(public.<>) new.script) OR (COALESCE(old.results_tag, ''::public.citext) OPERATOR(public.<>) COALESCE(new.results_tag, ''::public.citext)) OR ((COALESCE(old.contents, ''::xml))::text <> (COALESCE(new.contents, ''::xml))::text))) EXECUTE FUNCTION sw.trigfn_t_scripts_after_update();

--
-- Name: TABLE t_scripts; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_scripts TO readaccess;

