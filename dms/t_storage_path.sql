--
-- Name: t_storage_path; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_storage_path (
    storage_path_id integer NOT NULL,
    storage_path public.citext NOT NULL,
    machine_name public.citext,
    vol_name_client public.citext,
    vol_name_server public.citext,
    storage_path_function public.citext NOT NULL,
    instrument public.citext,
    storage_path_code public.citext,
    description public.citext,
    url public.citext GENERATED ALWAYS AS (
CASE
    WHEN (storage_path_function OPERATOR(public.~~) '%inbox'::public.citext) THEN NULL::text
    ELSE ((('http://'::text || (machine_name)::text) || '/'::text) || public.replace(storage_path, '\'::public.citext, '/'::public.citext))
END) STORED,
    url_https public.citext GENERATED ALWAYS AS (
CASE
    WHEN (storage_path_function OPERATOR(public.~~) '%inbox'::public.citext) THEN NULL::text
    ELSE (((('https://'::text || (machine_name)::text) ||
    CASE
        WHEN (url_domain OPERATOR(public.=) ''::public.citext) THEN ''::text
        ELSE ('.'::text || (url_domain)::text)
    END) || '/'::text) || public.replace(storage_path, '\'::public.citext, '/'::public.citext))
END) STORED,
    url_domain public.citext NOT NULL,
    created timestamp without time zone
);


ALTER TABLE public.t_storage_path OWNER TO d3l243;

--
-- Name: TABLE t_storage_path; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_storage_path TO readaccess;

