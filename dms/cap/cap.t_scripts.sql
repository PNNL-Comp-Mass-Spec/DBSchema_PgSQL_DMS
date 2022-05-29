--
-- Name: t_scripts; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_scripts (
    script_id integer NOT NULL,
    script public.citext NOT NULL,
    description public.citext,
    enabled character(1) DEFAULT 'N'::bpchar NOT NULL,
    results_tag public.citext,
    contents xml
);


ALTER TABLE cap.t_scripts OWNER TO d3l243;

--
-- Name: t_scripts pk_t_scripts; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_scripts
    ADD CONSTRAINT pk_t_scripts PRIMARY KEY (script_id);

--
-- Name: ix_t_scripts; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_scripts ON cap.t_scripts USING btree (script);

