--
-- Name: t_instrument_group_allocation_tag; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_group_allocation_tag (
    allocation_tag public.citext NOT NULL,
    allocation_description public.citext CONSTRAINT t_instrument_group_allocation_t_allocation_description_not_null NOT NULL
);


ALTER TABLE public.t_instrument_group_allocation_tag OWNER TO d3l243;

--
-- Name: t_instrument_group_allocation_tag pk_t_instrument_group_allocation_tag; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_group_allocation_tag
    ADD CONSTRAINT pk_t_instrument_group_allocation_tag PRIMARY KEY (allocation_tag);

ALTER TABLE public.t_instrument_group_allocation_tag CLUSTER ON pk_t_instrument_group_allocation_tag;

--
-- Name: TABLE t_instrument_group_allocation_tag; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_group_allocation_tag TO readaccess;
GRANT SELECT ON TABLE public.t_instrument_group_allocation_tag TO writeaccess;

