--
-- Name: t_cached_instrument_usage_by_proposal; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_instrument_usage_by_proposal (
    instrument_group public.citext NOT NULL,
    eus_proposal_id public.citext NOT NULL,
    actual_hours double precision
);


ALTER TABLE public.t_cached_instrument_usage_by_proposal OWNER TO d3l243;

--
-- Name: TABLE t_cached_instrument_usage_by_proposal; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_instrument_usage_by_proposal TO readaccess;

