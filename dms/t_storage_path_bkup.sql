--
-- Name: t_storage_path_bkup; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_storage_path_bkup (
    storage_path_id integer NOT NULL,
    storage_path public.citext NOT NULL,
    vol_name_client public.citext,
    vol_name_server public.citext,
    storage_path_function public.citext,
    instrument public.citext,
    storage_path_code public.citext,
    description public.citext
);


ALTER TABLE public.t_storage_path_bkup OWNER TO d3l243;

--
-- Name: TABLE t_storage_path_bkup; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_storage_path_bkup TO readaccess;

