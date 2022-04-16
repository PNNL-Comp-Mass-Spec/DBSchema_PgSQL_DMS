--
-- Name: t_misc_paths; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_misc_paths (
    path_function character(32) NOT NULL,
    path_id integer NOT NULL,
    server public.citext,
    client public.citext NOT NULL,
    comment public.citext NOT NULL
);


ALTER TABLE public.t_misc_paths OWNER TO d3l243;

--
-- Name: TABLE t_misc_paths; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_misc_paths TO readaccess;

