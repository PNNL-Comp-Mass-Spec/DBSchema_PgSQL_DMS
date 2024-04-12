--
-- Name: t_scripts; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_scripts (
    script_id integer NOT NULL,
    script public.citext NOT NULL,
    description public.citext,
    enabled public.citext DEFAULT 'N'::bpchar NOT NULL,
    results_tag public.citext,
    contents xml
);


ALTER TABLE cap.t_scripts OWNER TO d3l243;

--
-- Name: t_scripts_script_id_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_scripts ALTER COLUMN script_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_scripts_script_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_scripts pk_t_scripts; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_scripts
    ADD CONSTRAINT pk_t_scripts PRIMARY KEY (script_id);

--
-- Name: ix_t_scripts; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_scripts ON cap.t_scripts USING btree (script);

--
-- Name: t_scripts trig_t_scripts_after_delete; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_scripts_after_delete AFTER DELETE ON cap.t_scripts REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_scripts_after_delete();

--
-- Name: t_scripts trig_t_scripts_after_insert; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_scripts_after_insert AFTER INSERT ON cap.t_scripts REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_scripts_after_insert();

--
-- Name: t_scripts trig_t_scripts_after_update; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_scripts_after_update AFTER UPDATE ON cap.t_scripts FOR EACH ROW WHEN (((new.script OPERATOR(public.<>) old.script) OR (COALESCE(new.results_tag, ''::public.citext) OPERATOR(public.<>) COALESCE(old.results_tag, ''::public.citext)) OR ((COALESCE(new.contents, ''::xml))::text <> (COALESCE(old.contents, ''::xml))::text))) EXECUTE FUNCTION cap.trigfn_t_scripts_after_update();

--
-- Name: TABLE t_scripts; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_scripts TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_scripts TO writeaccess;

