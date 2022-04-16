--
-- Name: t_instrument_allocation_updates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_allocation_updates (
    entry_id integer NOT NULL,
    allocation_tag public.citext NOT NULL,
    proposal_id public.citext NOT NULL,
    fiscal_year integer,
    allocated_hours_old double precision,
    allocated_hours_new double precision,
    comment public.citext,
    entered timestamp without time zone,
    entered_by public.citext
);


ALTER TABLE public.t_instrument_allocation_updates OWNER TO d3l243;

--
-- Name: TABLE t_instrument_allocation_updates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_allocation_updates TO readaccess;

