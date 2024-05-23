--
-- Name: v_ai_user_funded_datasets; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_ai_user_funded_datasets AS
 SELECT ds.dataset,
    instname.instrument,
    ds.created AS date,
    e.experiment,
    ai.value AS proposal_number
   FROM (((public.t_experiments e
     JOIN public.v_aux_info_value ai ON ((e.exp_id = ai.target_id)))
     JOIN public.t_dataset ds ON ((e.exp_id = ds.exp_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
  WHERE ((ai.target OPERATOR(public.=) 'Experiment'::public.citext) AND (ai.category OPERATOR(public.=) 'Accounting'::public.citext) AND (ai.subcategory OPERATOR(public.=) 'Funding'::public.citext) AND (ai.item OPERATOR(public.=) 'Proposal Number'::public.citext) AND (ai.value OPERATOR(public.<>) ''::public.citext));


ALTER VIEW public.v_ai_user_funded_datasets OWNER TO d3l243;

--
-- Name: TABLE v_ai_user_funded_datasets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_ai_user_funded_datasets TO readaccess;
GRANT SELECT ON TABLE public.v_ai_user_funded_datasets TO writeaccess;

