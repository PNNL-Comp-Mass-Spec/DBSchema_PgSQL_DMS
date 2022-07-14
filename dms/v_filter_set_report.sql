--
-- Name: v_filter_set_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_filter_set_report AS
 SELECT fst.filter_type_name,
    fs.filter_set_id,
    fs.filter_set_name,
    fs.filter_set_description,
    pr.filter_criteria_group_id,
    pr.charge,
    pr.high_normalized_score,
    pr.cleavage_state,
    pr.terminus_state,
    pr.del_cn,
    pr.del_cn2,
    pr.rank_score,
    pr.xtandem_hyperscore,
    pr.xtandem_log_evalue,
    pr.peptide_prophet_probability,
    pr.msgf_spec_prob,
    pr.msgfdb_spec_prob,
    pr.msgfdb_pvalue,
    pr.msgfplus_qvalue,
    pr.msgfplus_pep_qvalue,
    pr.msalign_pvalue,
    pr.msalign_fdr,
    pr.inspect_mqscore,
    pr.inspect_total_prmscore,
    pr.inspect_fscore,
    pr.inspect_pvalue,
    pr.discriminant_score,
    pr.net_difference_absolute,
    pr.discriminant_initial_filter,
    pr.peptide_length,
    pr.mass,
    pr.spectrum_count,
    pr.protein_count
   FROM (((( SELECT pivotdata.filter_criteria_group_id,
            pivotdata."2" AS charge,
            pivotdata."3" AS high_normalized_score,
            pivotdata."4" AS cleavage_state,
            pivotdata."13" AS terminus_state,
            pivotdata."7" AS del_cn,
            pivotdata."8" AS del_cn2,
            pivotdata."17" AS rank_score,
            pivotdata."14" AS xtandem_hyperscore,
            pivotdata."15" AS xtandem_log_evalue,
            pivotdata."16" AS peptide_prophet_probability,
            pivotdata."22" AS msgf_spec_prob,
            pivotdata."23" AS msgfdb_spec_prob,
            pivotdata."24" AS msgfdb_pvalue,
            pivotdata."25" AS msgfplus_qvalue,
            pivotdata."28" AS msgfplus_pep_qvalue,
            pivotdata."26" AS msalign_pvalue,
            pivotdata."27" AS msalign_fdr,
            pivotdata."18" AS inspect_mqscore,
            pivotdata."19" AS inspect_total_prmscore,
            pivotdata."20" AS inspect_fscore,
            pivotdata."21" AS inspect_pvalue,
            pivotdata."9" AS discriminant_score,
            pivotdata."10" AS net_difference_absolute,
            pivotdata."11" AS discriminant_initial_filter,
            pivotdata."5" AS peptide_length,
            pivotdata."6" AS mass,
            pivotdata."1" AS spectrum_count,
            pivotdata."12" AS protein_count
           FROM public.crosstab('SELECT FSC.Filter_Criteria_Group_ID,
                FSC.Criterion_id,
                FSC.Criterion_Comparison || FSC.Criterion_Value::text AS Criterion
         FROM public.t_filter_set_criteria FSC
         ORDER BY 1, 2'::text, 'SELECT generate_series(1,28)'::text) pivotdata(filter_criteria_group_id integer, "1" text, "2" text, "3" text, "4" text, "5" text, "6" text, "7" text, "8" text, "9" text, "10" text, "11" text, "12" text, "13" text, "14" text, "15" text, "16" text, "17" text, "18" text, "19" text, "20" text, "21" text, "22" text, "23" text, "24" text, "25" text, "26" text, "27" text, "28" text)) pr
     JOIN public.t_filter_set_criteria_groups fscg ON ((pr.filter_criteria_group_id = fscg.filter_criteria_group_id)))
     JOIN public.t_filter_sets fs ON ((fscg.filter_set_id = fs.filter_set_id)))
     JOIN public.t_filter_set_types fst ON ((fs.filter_type_id = fst.filter_type_id)));


ALTER TABLE public.v_filter_set_report OWNER TO d3l243;

--
-- Name: TABLE v_filter_set_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_filter_set_report TO readaccess;

