--
-- Name: v_protein_options_seq_direction; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_protein_options_seq_direction AS
 SELECT string_element AS ex,
    display_value AS val
   FROM pc.v_creation_string_lookup
  WHERE (keyword OPERATOR(public.=) 'seq_direction'::public.citext);


ALTER VIEW public.v_protein_options_seq_direction OWNER TO d3l243;

--
-- Name: TABLE v_protein_options_seq_direction; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_protein_options_seq_direction TO readaccess;
GRANT SELECT ON TABLE public.v_protein_options_seq_direction TO writeaccess;

