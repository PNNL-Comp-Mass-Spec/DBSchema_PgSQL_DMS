--
-- Name: t_remote_info; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_remote_info (
    remote_info_id integer NOT NULL,
    remote_info public.citext NOT NULL,
    most_recent_job integer,
    last_used timestamp without time zone,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    max_running_job_steps integer DEFAULT 2 NOT NULL
);


ALTER TABLE sw.t_remote_info OWNER TO d3l243;

--
-- Name: t_remote_info_remote_info_id_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_remote_info ALTER COLUMN remote_info_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_remote_info_remote_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_remote_info pk_t_remote_info; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_remote_info
    ADD CONSTRAINT pk_t_remote_info PRIMARY KEY (remote_info_id);

--
-- Name: ix_t_remote_info; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_remote_info ON sw.t_remote_info USING btree (remote_info);

