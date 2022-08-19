--
-- Name: t_internal_std_parent_mixes; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_internal_std_parent_mixes (
    parent_mix_id integer NOT NULL,
    name public.citext NOT NULL,
    description public.citext,
    protein_collection_name public.citext NOT NULL
);


ALTER TABLE public.t_internal_std_parent_mixes OWNER TO d3l243;

--
-- Name: t_internal_std_parent_mixes pk_t_internal_std_mixes; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_internal_std_parent_mixes
    ADD CONSTRAINT pk_t_internal_std_mixes PRIMARY KEY (parent_mix_id);

--
-- Name: TABLE t_internal_std_parent_mixes; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_internal_std_parent_mixes TO readaccess;
GRANT SELECT ON TABLE public.t_internal_std_parent_mixes TO writeaccess;

