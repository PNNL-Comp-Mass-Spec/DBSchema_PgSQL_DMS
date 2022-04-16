--
-- Name: t_eus_proposals; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_eus_proposals (
    proposal_id public.citext NOT NULL,
    title public.citext,
    state_id integer NOT NULL,
    import_date timestamp without time zone NOT NULL,
    proposal_type public.citext,
    proposal_start_date timestamp without time zone,
    proposal_end_date timestamp without time zone,
    last_affected timestamp without time zone,
    numeric_id public.citext GENERATED ALWAYS AS (public.extract_integer((proposal_id)::text)) STORED,
    proposal_id_auto_supersede public.citext
);


ALTER TABLE public.t_eus_proposals OWNER TO d3l243;

--
-- Name: TABLE t_eus_proposals; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_eus_proposals TO readaccess;

