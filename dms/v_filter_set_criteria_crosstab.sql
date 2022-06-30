--
-- Name: v_filter_set_criteria_crosstab; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_filter_set_criteria_crosstab AS
 SELECT pivotdata.filter_set_id,
    pivotdata.filter_set_name,
    pivotdata.filter_set_description,
    pivotdata.filter_criteria_group_id,
    COALESCE(pivotdata.charge, 0) AS charge,
    COALESCE(pivotdata.high_normalized_score, (0)::double precision) AS high_normalized_score,
    COALESCE(pivotdata.cleavage_state, 0) AS cleavage_state,
    COALESCE(pivotdata.terminus_state, 0) AS terminus_state,
    COALESCE(pivotdata.delcn, (0)::double precision) AS del_cn,
    COALESCE(pivotdata.delcn2, (0)::double precision) AS del_cn2,
    COALESCE(pivotdata.rankscore, 0) AS rank_score,
    COALESCE(pivotdata.xtandem_hyperscore, (0)::double precision) AS xtandem_hyperscore,
    COALESCE(pivotdata.xtandem_logevalue, (0)::double precision) AS xtandem_log_evalue,
    COALESCE(pivotdata.peptide_prophet_probability, (0)::double precision) AS peptide_prophet_probability,
    COALESCE(pivotdata.msgf_specprob, (0)::double precision) AS msgf_spec_prob,
    COALESCE(pivotdata.msgfdb_specprob, (0)::double precision) AS msgfdb_spec_prob,
    COALESCE(pivotdata.msgfdb_pvalue, (0)::double precision) AS msgfdb_pvalue,
    COALESCE(pivotdata.msgfplus_qvalue, (0)::double precision) AS msgfplus_qvalue,
    COALESCE(pivotdata.msgfplus_pepqvalue, (0)::double precision) AS msgfplus_pep_qvalue,
    COALESCE(pivotdata.msalign_pvalue, (0)::double precision) AS msalign_pvalue,
    COALESCE(pivotdata.msalign_fdr, (0)::double precision) AS msalign_fdr,
    COALESCE(pivotdata.inspect_mqscore, (0)::double precision) AS inspect_mqscore,
    COALESCE(pivotdata.inspect_totalprmscore, (0)::double precision) AS inspect_total_prmscore,
    COALESCE(pivotdata.inspect_fscore, (0)::double precision) AS inspect_fscore,
    COALESCE(pivotdata.inspect_pvalue, (0)::double precision) AS inspect_pvalue,
    COALESCE(pivotdata.discriminant_score, (0)::double precision) AS discriminant_score,
    COALESCE(pivotdata.net_difference_absolute, (0)::double precision) AS net_difference_absolute,
    COALESCE(pivotdata.discriminant_initial_filter, (0)::double precision) AS discriminant_initial_filter,
    COALESCE(pivotdata.peptide_length, 0) AS peptide_length,
    COALESCE(pivotdata.mass, (0)::double precision) AS mass,
    COALESCE(pivotdata.spectrum_count, 0) AS spectrum_count,
    COALESCE(pivotdata.protein_count, 0) AS protein_count
   FROM public.crosstab('SELECT Filter_Criteria_Group_ID, Filter_Set_ID, Filter_Set_Name, Filter_Set_Description, Criterion_Name, Criterion_Value
    FROM V_Filter_Set_Criteria
    ORDER BY Filter_Set_ID, Filter_Criteria_Group_ID, Criterion_Name'::text, 'SELECT unnest(''{Spectrum_Count, Charge, High_Normalized_Score, Cleavage_State, Peptide_Length,
                     Mass, DelCn, DelCn2, Discriminant_Score, NET_Difference_Absolute, Discriminant_Initial_Filter, Protein_Count, Terminus_State,
                     XTandem_Hyperscore, XTandem_LogEValue, Peptide_Prophet_Probability, RankScore,
                     Inspect_MQScore, Inspect_TotalPRMScore, Inspect_FScore, Inspect_PValue,
                     MSGF_SpecProb, MSGFDB_SpecProb, MSGFDB_PValue, MSGFPlus_QValue, MSGFPlus_PepQValue,
                     MSAlign_PValue, MSAlign_FDR}''::text[])'::text) pivotdata(filter_criteria_group_id integer, filter_set_id integer, filter_set_name public.citext, filter_set_description public.citext, spectrum_count integer, charge integer, high_normalized_score double precision, cleavage_state integer, peptide_length integer, mass double precision, delcn double precision, delcn2 double precision, discriminant_score double precision, net_difference_absolute double precision, discriminant_initial_filter double precision, protein_count integer, terminus_state integer, xtandem_hyperscore double precision, xtandem_logevalue double precision, peptide_prophet_probability double precision, rankscore integer, inspect_mqscore double precision, inspect_totalprmscore double precision, inspect_fscore double precision, inspect_pvalue double precision, msgf_specprob double precision, msgfdb_specprob double precision, msgfdb_pvalue double precision, msgfplus_qvalue double precision, msgfplus_pepqvalue double precision, msalign_pvalue double precision, msalign_fdr double precision);


ALTER TABLE public.v_filter_set_criteria_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_filter_set_criteria_crosstab; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_filter_set_criteria_crosstab TO readaccess;

