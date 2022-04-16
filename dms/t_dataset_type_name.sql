--
-- Name: t_dataset_type_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_type_name (
    dataset_type_id integer NOT NULL,
    dataset_type public.citext NOT NULL,
    description public.citext,
    active smallint NOT NULL
);


ALTER TABLE public.t_dataset_type_name OWNER TO d3l243;

--
-- Name: TABLE t_dataset_type_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_type_name TO readaccess;

