--
-- Name: t_signatures; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_signatures (
    reference integer NOT NULL,
    pattern public.citext NOT NULL,
    string public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_used timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE sw.t_signatures OWNER TO d3l243;

--
-- Name: t_signatures_reference_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_signatures ALTER COLUMN reference ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_signatures_reference_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_signatures pk_t_signatures; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_signatures
    ADD CONSTRAINT pk_t_signatures PRIMARY KEY (reference);

--
-- Name: ix_t_signatures; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_signatures ON sw.t_signatures USING btree (pattern);

