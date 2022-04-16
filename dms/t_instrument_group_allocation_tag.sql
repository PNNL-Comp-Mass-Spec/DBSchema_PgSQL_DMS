--
-- Name: t_instrument_group_allocation_tag; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_group_allocation_tag (
    allocation_tag public.citext NOT NULL,
    allocation_description public.citext NOT NULL
);


ALTER TABLE public.t_instrument_group_allocation_tag OWNER TO d3l243;

--
-- Name: TABLE t_instrument_group_allocation_tag; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_group_allocation_tag TO readaccess;

