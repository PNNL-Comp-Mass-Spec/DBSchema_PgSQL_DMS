--
-- Name: t_settings_files; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_settings_files (
    settings_file_id integer NOT NULL,
    analysis_tool public.citext NOT NULL,
    file_name public.citext NOT NULL,
    description public.citext,
    active smallint,
    contents xml,
    job_usage_count integer,
    hms_auto_supersede public.citext,
    msgfplus_auto_centroid public.citext,
    comment public.citext,
    created timestamp without time zone,
    last_updated timestamp without time zone,
    job_usage_last_year integer
);


ALTER TABLE public.t_settings_files OWNER TO d3l243;

--
-- Name: t_settings_files_settings_file_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_settings_files ALTER COLUMN settings_file_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_settings_files_settings_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_settings_files pk_t_settings_files; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_settings_files
    ADD CONSTRAINT pk_t_settings_files PRIMARY KEY (settings_file_id);

--
-- Name: TABLE t_settings_files; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_settings_files TO readaccess;

