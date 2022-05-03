--
-- Name: t_param_files; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_param_files (
    param_file_id integer NOT NULL,
    param_file_name public.citext NOT NULL,
    param_file_description public.citext,
    param_file_type_id integer NOT NULL,
    date_created timestamp without time zone,
    date_modified timestamp without time zone,
    valid smallint NOT NULL,
    job_usage_count integer,
    job_usage_last_year integer,
    mod_list public.citext NOT NULL
);


ALTER TABLE public.t_param_files OWNER TO d3l243;

--
-- Name: t_param_files_param_file_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_param_files ALTER COLUMN param_file_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_param_files_param_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_param_files pk_t_param_files; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_files
    ADD CONSTRAINT pk_t_param_files PRIMARY KEY (param_file_id);

--
-- Name: ix_t_param_files_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_param_files_name ON public.t_param_files USING btree (param_file_name);

--
-- Name: TABLE t_param_files; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_param_files TO readaccess;

