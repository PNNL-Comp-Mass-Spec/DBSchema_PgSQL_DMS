--
-- Name: t_instrument_allocation; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_allocation (
    allocation_tag public.citext NOT NULL,
    proposal_id public.citext NOT NULL,
    fiscal_year integer NOT NULL,
    allocated_hours double precision,
    comment public.citext DEFAULT ''::public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fy_proposal public.citext GENERATED ALWAYS AS (((((fiscal_year)::public.citext)::text || '_'::text) || (proposal_id)::text)) STORED
);


ALTER TABLE public.t_instrument_allocation OWNER TO d3l243;

--
-- Name: t_instrument_allocation pk_t_instrument_allocation; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_allocation
    ADD CONSTRAINT pk_t_instrument_allocation PRIMARY KEY (allocation_tag, proposal_id, fiscal_year);

--
-- Name: t_instrument_allocation trig_t_instrument_allocation_after_delete; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_instrument_allocation_after_delete AFTER DELETE ON public.t_instrument_allocation REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_instrument_allocation_after_delete();

--
-- Name: t_instrument_allocation trig_t_instrument_allocation_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_instrument_allocation_after_insert AFTER INSERT ON public.t_instrument_allocation REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_instrument_allocation_after_insert();

--
-- Name: t_instrument_allocation trig_t_instrument_allocation_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_instrument_allocation_after_update AFTER UPDATE ON public.t_instrument_allocation FOR EACH ROW WHEN (((old.allocated_hours IS DISTINCT FROM new.allocated_hours) OR (old.comment IS DISTINCT FROM new.comment))) EXECUTE FUNCTION public.trigfn_t_instrument_allocation_after_update();

--
-- Name: TABLE t_instrument_allocation; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_allocation TO readaccess;
GRANT SELECT ON TABLE public.t_instrument_allocation TO writeaccess;

