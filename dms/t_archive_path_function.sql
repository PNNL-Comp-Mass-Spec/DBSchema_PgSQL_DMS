--
-- Name: t_archive_path_function; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_archive_path_function (
    apf_function public.citext NOT NULL
);


ALTER TABLE public.t_archive_path_function OWNER TO d3l243;

--
-- Name: t_archive_path_function pk_t_archive_path_function; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_archive_path_function
    ADD CONSTRAINT pk_t_archive_path_function PRIMARY KEY (apf_function);

--
-- Name: TABLE t_archive_path_function; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_archive_path_function TO readaccess;
GRANT SELECT ON TABLE public.t_archive_path_function TO writeaccess;

