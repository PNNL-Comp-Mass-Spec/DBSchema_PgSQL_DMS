--
-- Name: t_dataset_rating_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_rating_name (
    dataset_rating_id smallint NOT NULL,
    dataset_rating public.citext NOT NULL
);


ALTER TABLE public.t_dataset_rating_name OWNER TO d3l243;

--
-- Name: t_dataset_rating_name pk_t_dataset_rating_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_rating_name
    ADD CONSTRAINT pk_t_dataset_rating_name PRIMARY KEY (dataset_rating_id);

ALTER TABLE public.t_dataset_rating_name CLUSTER ON pk_t_dataset_rating_name;

--
-- Name: TABLE t_dataset_rating_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_rating_name TO readaccess;
GRANT SELECT ON TABLE public.t_dataset_rating_name TO writeaccess;

