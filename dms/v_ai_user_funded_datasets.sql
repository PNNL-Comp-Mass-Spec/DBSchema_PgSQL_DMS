--
-- Name: v_ai_user_funded_datasets; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_ai_user_funded_datasets AS
 SELECT t_dataset.dataset,
    t_instrument_name.instrument,
    t_dataset.created AS date,
    t.experiment,
    ai.value AS proposal_number
   FROM (((public.v_experiment_detail_report_ex t
     JOIN public.v_aux_info_value ai ON ((t.id = ai.target_id)))
     JOIN public.t_dataset ON ((t.id = t_dataset.exp_id)))
     JOIN public.t_instrument_name ON ((t_dataset.instrument_id = t_instrument_name.instrument_id)))
  WHERE ((ai.target OPERATOR(public.=) 'Experiment'::public.citext) AND (ai.category OPERATOR(public.=) 'Accounting'::public.citext) AND (ai.subcategory OPERATOR(public.=) 'Funding'::public.citext) AND (ai.item OPERATOR(public.=) 'Proposal Number'::public.citext) AND (ai.value OPERATOR(public.<>) ''::public.citext));


ALTER VIEW public.v_ai_user_funded_datasets OWNER TO d3l243;

--
-- Name: TABLE v_ai_user_funded_datasets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_ai_user_funded_datasets TO readaccess;
GRANT SELECT ON TABLE public.v_ai_user_funded_datasets TO writeaccess;

