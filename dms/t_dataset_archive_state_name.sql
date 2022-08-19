--
-- Name: t_dataset_archive_state_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_archive_state_name (
    archive_state_id integer NOT NULL,
    archive_state public.citext,
    comment public.citext
);


ALTER TABLE public.t_dataset_archive_state_name OWNER TO d3l243;

--
-- Name: t_dataset_archive_state_name pk_t_dataset_archive_state_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_archive_state_name
    ADD CONSTRAINT pk_t_dataset_archive_state_name PRIMARY KEY (archive_state_id);

--
-- Name: TABLE t_dataset_archive_state_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_archive_state_name TO readaccess;
GRANT SELECT ON TABLE public.t_dataset_archive_state_name TO writeaccess;

