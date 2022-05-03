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
-- Name: t_emsl_instrument_allocation pk_t_emsl_instrument_allocation; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_emsl_instrument_allocation
    ADD CONSTRAINT pk_t_emsl_instrument_allocation PRIMARY KEY (eus_instrument_id, proposal_id, fy);

--
-- Name: TABLE t_emsl_instrument_allocation; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_emsl_instrument_allocation TO readaccess;

