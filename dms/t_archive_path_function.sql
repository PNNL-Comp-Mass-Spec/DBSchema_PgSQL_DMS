--
-- Name: t_archive_path_function; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_archive_path_function (
    apf_function public.citext NOT NULL
);


ALTER TABLE public.t_archive_path_function OWNER TO d3l243;

--
-- Name: TABLE t_archive_path_function; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_archive_path_function TO readaccess;

