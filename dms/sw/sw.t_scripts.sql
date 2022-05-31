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

