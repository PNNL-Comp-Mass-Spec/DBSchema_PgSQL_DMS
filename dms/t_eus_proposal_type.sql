--
-- Name: t_eus_proposal_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_eus_proposal_type (
    proposal_type public.citext NOT NULL,
    proposal_type_name public.citext NOT NULL,
    abbreviation public.citext NOT NULL,
    comment public.citext
);


ALTER TABLE public.t_eus_proposal_type OWNER TO d3l243;

--
-- Name: TABLE t_eus_proposal_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_eus_proposal_type TO readaccess;

