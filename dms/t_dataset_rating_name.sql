--
-- Name: t_dataset_rating_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_rating_name (
    dataset_rating_id smallint NOT NULL,
    dataset_rating public.citext NOT NULL
);


ALTER TABLE public.t_dataset_rating_name OWNER TO d3l243;

--
-- Name: TABLE t_dataset_rating_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_rating_name TO readaccess;

