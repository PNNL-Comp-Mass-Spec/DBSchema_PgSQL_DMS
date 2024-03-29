--
-- Name: v_instrument_name_rna_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_name_rna_picklist AS
 SELECT instname.instrument,
    i.usage,
    (public.get_instrument_group_dataset_type_list((i.instrument_group)::text, ', '::text))::public.citext AS allowed_dataset_types
   FROM ((public.t_instrument_name instname
     JOIN public.t_instrument_group i ON ((instname.instrument_group OPERATOR(public.=) i.instrument_group)))
     LEFT JOIN public.t_dataset_type_name dt ON ((i.default_dataset_type = dt.dataset_type_id)))
  WHERE ((instname.operations_role OPERATOR(public.=) 'Transcriptomics'::public.citext) AND (instname.status OPERATOR(public.<>) 'Inactive'::public.citext));


ALTER VIEW public.v_instrument_name_rna_picklist OWNER TO d3l243;

--
-- Name: TABLE v_instrument_name_rna_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_name_rna_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_name_rna_picklist TO writeaccess;

