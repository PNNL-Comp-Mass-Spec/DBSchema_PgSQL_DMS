--
-- Name: v_instrument_status_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_status_picklist AS
 SELECT unnest('{active,inactive,offline,broken}'::text[]) AS val;


ALTER TABLE public.v_instrument_status_picklist OWNER TO d3l243;

--
-- Name: TABLE v_instrument_status_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_status_picklist TO readaccess;

