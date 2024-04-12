--
-- Name: v_nexus_import_requested_allocated_hours; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_nexus_import_requested_allocated_hours AS
 SELECT instrument_id,
    eus_display_name,
    proposal_id,
    requested_hours,
    allocated_hours,
    fy
   FROM eus.vw_requested_allocated_hours;


ALTER VIEW public.v_nexus_import_requested_allocated_hours OWNER TO d3l243;

--
-- Name: TABLE v_nexus_import_requested_allocated_hours; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_nexus_import_requested_allocated_hours TO readaccess;
GRANT SELECT ON TABLE public.v_nexus_import_requested_allocated_hours TO writeaccess;

