--
-- Name: v_eus_import_requested_allocated_hours; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_import_requested_allocated_hours AS
 SELECT vw_requested_allocated_hours.instrument_id,
    vw_requested_allocated_hours.eus_display_name,
    vw_requested_allocated_hours.proposal_id,
    vw_requested_allocated_hours.requested_hours,
    vw_requested_allocated_hours.allocated_hours,
    vw_requested_allocated_hours.fy
   FROM eus.vw_requested_allocated_hours;


ALTER TABLE public.v_eus_import_requested_allocated_hours OWNER TO d3l243;

--
-- Name: TABLE v_eus_import_requested_allocated_hours; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_import_requested_allocated_hours TO readaccess;
GRANT SELECT ON TABLE public.v_eus_import_requested_allocated_hours TO writeaccess;

