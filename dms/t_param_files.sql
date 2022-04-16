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
-- Name: TABLE t_param_files; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_param_files TO readaccess;

