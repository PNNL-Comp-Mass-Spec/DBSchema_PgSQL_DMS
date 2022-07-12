--
-- Name: v_enzyme_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_enzyme_picklist AS
 SELECT t_enzymes.enzyme_id AS id,
    t_enzymes.enzyme_name AS name
   FROM public.t_enzymes
  WHERE (t_enzymes.enzyme_id > 0);


ALTER TABLE public.v_enzyme_picklist OWNER TO d3l243;

--
-- Name: TABLE v_enzyme_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_enzyme_picklist TO readaccess;

