--
-- Name: v_run_interval_usage; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_run_interval_usage AS
 SELECT t_run_interval.interval_id AS id,
    COALESCE(xmlnode.user_remote, '0'::text) AS user_remote,
    COALESCE(xmlnode.user_onsite, '0'::text) AS user_onsite,
    COALESCE(xmlnode."user", '0'::text) AS "user",
    COALESCE(xmlnode.user_proposal, '0'::text) AS user_proposal,
    COALESCE(xmlnode.broken, '0'::text) AS broken,
    COALESCE(xmlnode.maintenance, '0'::text) AS maintenance,
    COALESCE(xmlnode.staff_not_available, '0'::text) AS staff_not_available,
    COALESCE(xmlnode.cap_dev, '0'::text) AS cap_dev,
    COALESCE(xmlnode.instrument_available, '0'::text) AS instrument_available
   FROM public.t_run_interval,
    LATERAL XMLTABLE(('//u'::text) PASSING (t_run_interval.usage) COLUMNS user_remote text PATH ('@UserRemote'::text), user_onsite text PATH ('@UserOnsite'::text), "user" text PATH ('@User'::text), user_proposal text PATH ('@Proposal'::text), broken text PATH ('@Broken'::text), maintenance text PATH ('@Maintenance'::text), staff_not_available text PATH ('@StaffNotAvailable'::text), cap_dev text PATH ('@CapDev'::text), instrument_available text PATH ('@InstrumentAvailable'::text)) xmlnode
  WHERE ((t_run_interval.usage)::text <> ''::text);


ALTER TABLE public.v_run_interval_usage OWNER TO d3l243;

--
-- Name: TABLE v_run_interval_usage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_run_interval_usage TO readaccess;

