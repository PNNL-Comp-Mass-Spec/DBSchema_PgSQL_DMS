--
-- Name: t_emsl_instrument_allocation; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_emsl_instrument_allocation (
    eus_instrument_id integer NOT NULL,
    proposal_id public.citext NOT NULL,
    fy public.citext NOT NULL,
    allocated_hours integer,
    ext_display_name public.citext,
    ext_requested_hours integer,
    last_affected timestamp without time zone
);


ALTER TABLE public.t_emsl_instrument_allocation OWNER TO d3l243;

--
-- Name: TABLE t_emsl_instrument_allocation; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_emsl_instrument_allocation TO readaccess;

