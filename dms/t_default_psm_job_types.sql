--
-- Name: t_default_psm_job_types; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_default_psm_job_types (
    job_type_id integer NOT NULL,
    job_type_name public.citext NOT NULL,
    job_type_description public.citext
);


ALTER TABLE public.t_default_psm_job_types OWNER TO d3l243;

--
-- Name: TABLE t_default_psm_job_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_default_psm_job_types TO readaccess;

