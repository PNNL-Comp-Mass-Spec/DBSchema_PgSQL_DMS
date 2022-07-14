--
-- Name: v_experiment_plex_members_tsv_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_plex_members_tsv_entry AS
 SELECT expidpivotq.plex_exp_id AS exp_id,
    e.experiment,
    expidpivotq.channel1_expid AS channel1_exp_id,
    expidpivotq.channel2_expid AS channel2_exp_id,
    expidpivotq.channel3_expid AS channel3_exp_id,
    expidpivotq.channel4_expid AS channel4_exp_id,
    expidpivotq.channel5_expid AS channel5_exp_id,
    expidpivotq.channel6_expid AS channel6_exp_id,
    expidpivotq.channel7_expid AS channel7_exp_id,
    expidpivotq.channel8_expid AS channel8_exp_id,
    expidpivotq.channel9_expid AS channel9_exp_id,
    expidpivotq.channel10_expid AS channel10_exp_id,
    expidpivotq.channel11_expid AS channel11_exp_id,
    expidpivotq.channel12_expid AS channel12_exp_id,
    expidpivotq.channel13_expid AS channel13_exp_id,
    expidpivotq.channel14_expid AS channel14_exp_id,
    expidpivotq.channel15_expid AS channel15_exp_id,
    expidpivotq.channel16_expid AS channel16_exp_id,
    expidpivotq.channel17_expid AS channel17_exp_id,
    expidpivotq.channel18_expid AS channel18_exp_id,
    channeltypepivotq.channel1_type,
    channeltypepivotq.channel2_type,
    channeltypepivotq.channel3_type,
    channeltypepivotq.channel4_type,
    channeltypepivotq.channel5_type,
    channeltypepivotq.channel6_type,
    channeltypepivotq.channel7_type,
    channeltypepivotq.channel8_type,
    channeltypepivotq.channel9_type,
    channeltypepivotq.channel10_type,
    channeltypepivotq.channel11_type,
    channeltypepivotq.channel12_type,
    channeltypepivotq.channel13_type,
    channeltypepivotq.channel14_type,
    channeltypepivotq.channel15_type,
    channeltypepivotq.channel16_type,
    channeltypepivotq.channel17_type,
    channeltypepivotq.channel18_type,
    commentpivotq.channel1_comment,
    commentpivotq.channel2_comment,
    commentpivotq.channel3_comment,
    commentpivotq.channel4_comment,
    commentpivotq.channel5_comment,
    commentpivotq.channel6_comment,
    commentpivotq.channel7_comment,
    commentpivotq.channel8_comment,
    commentpivotq.channel9_comment,
    commentpivotq.channel10_comment,
    commentpivotq.channel11_comment,
    commentpivotq.channel12_comment,
    commentpivotq.channel13_comment,
    commentpivotq.channel14_comment,
    commentpivotq.channel15_comment,
    commentpivotq.channel16_comment,
    commentpivotq.channel17_comment,
    commentpivotq.channel18_comment
   FROM (((( SELECT pivotdata.plex_exp_id,
            pivotdata."1" AS channel1_expid,
            pivotdata."2" AS channel2_expid,
            pivotdata."3" AS channel3_expid,
            pivotdata."4" AS channel4_expid,
            pivotdata."5" AS channel5_expid,
            pivotdata."6" AS channel6_expid,
            pivotdata."7" AS channel7_expid,
            pivotdata."8" AS channel8_expid,
            pivotdata."9" AS channel9_expid,
            pivotdata."10" AS channel10_expid,
            pivotdata."11" AS channel11_expid,
            pivotdata."12" AS channel12_expid,
            pivotdata."13" AS channel13_expid,
            pivotdata."14" AS channel14_expid,
            pivotdata."15" AS channel15_expid,
            pivotdata."16" AS channel16_expid,
            pivotdata."17" AS channel17_expid,
            pivotdata."18" AS channel18_expid
           FROM public.crosstab(' SELECT PM.Plex_Exp_ID,
                     PM.Channel,
                     PM.Exp_ID::text || '': '' || E.Experiment As ChannelExperiment
              FROM public.t_experiment_plex_members PM
                   INNER JOIN public.t_experiments E
                     On PM.Exp_ID = E.Exp_ID
              ORDER BY PM.Plex_Exp_ID, PM.Channel'::text, 'SELECT generate_series(1,18)'::text) pivotdata(plex_exp_id integer, "1" public.citext, "2" public.citext, "3" public.citext, "4" public.citext, "5" public.citext, "6" public.citext, "7" public.citext, "8" public.citext, "9" public.citext, "10" public.citext, "11" public.citext, "12" public.citext, "13" public.citext, "14" public.citext, "15" public.citext, "16" public.citext, "17" public.citext, "18" public.citext)) expidpivotq
     JOIN public.t_experiments e ON ((expidpivotq.plex_exp_id = e.exp_id)))
     JOIN ( SELECT pivotdata.plex_exp_id,
            pivotdata."1" AS channel1_type,
            pivotdata."2" AS channel2_type,
            pivotdata."3" AS channel3_type,
            pivotdata."4" AS channel4_type,
            pivotdata."5" AS channel5_type,
            pivotdata."6" AS channel6_type,
            pivotdata."7" AS channel7_type,
            pivotdata."8" AS channel8_type,
            pivotdata."9" AS channel9_type,
            pivotdata."10" AS channel10_type,
            pivotdata."11" AS channel11_type,
            pivotdata."12" AS channel12_type,
            pivotdata."13" AS channel13_type,
            pivotdata."14" AS channel14_type,
            pivotdata."15" AS channel15_type,
            pivotdata."16" AS channel16_type,
            pivotdata."17" AS channel17_type,
            pivotdata."18" AS channel18_type
           FROM public.crosstab(' SELECT PM.Plex_Exp_ID,
                     PM.Channel,
                     ChannelTypeName.Channel_Type_Name
              FROM public.t_experiment_plex_members PM
                   INNER JOIN public.t_experiment_plex_channel_type_name ChannelTypeName
                     On PM.Channel_Type_ID = ChannelTypeName.Channel_Type_ID
              ORDER BY PM.Plex_Exp_ID, PM.Channel'::text, 'SELECT generate_series(1,18)'::text) pivotdata(plex_exp_id integer, "1" public.citext, "2" public.citext, "3" public.citext, "4" public.citext, "5" public.citext, "6" public.citext, "7" public.citext, "8" public.citext, "9" public.citext, "10" public.citext, "11" public.citext, "12" public.citext, "13" public.citext, "14" public.citext, "15" public.citext, "16" public.citext, "17" public.citext, "18" public.citext)) channeltypepivotq ON ((expidpivotq.plex_exp_id = channeltypepivotq.plex_exp_id)))
     JOIN ( SELECT pivotdata.plex_exp_id,
            pivotdata."1" AS channel1_comment,
            pivotdata."2" AS channel2_comment,
            pivotdata."3" AS channel3_comment,
            pivotdata."4" AS channel4_comment,
            pivotdata."5" AS channel5_comment,
            pivotdata."6" AS channel6_comment,
            pivotdata."7" AS channel7_comment,
            pivotdata."8" AS channel8_comment,
            pivotdata."9" AS channel9_comment,
            pivotdata."10" AS channel10_comment,
            pivotdata."11" AS channel11_comment,
            pivotdata."12" AS channel12_comment,
            pivotdata."13" AS channel13_comment,
            pivotdata."14" AS channel14_comment,
            pivotdata."15" AS channel15_comment,
            pivotdata."16" AS channel16_comment,
            pivotdata."17" AS channel17_comment,
            pivotdata."18" AS channel18_comment
           FROM public.crosstab(' SELECT PM.Plex_Exp_ID,
                     PM.Channel,
                     PM.Comment
              FROM public.t_experiment_plex_members PM
              ORDER BY PM.Plex_Exp_ID, PM.Channel'::text, 'SELECT generate_series(1,18)'::text) pivotdata(plex_exp_id integer, "1" public.citext, "2" public.citext, "3" public.citext, "4" public.citext, "5" public.citext, "6" public.citext, "7" public.citext, "8" public.citext, "9" public.citext, "10" public.citext, "11" public.citext, "12" public.citext, "13" public.citext, "14" public.citext, "15" public.citext, "16" public.citext, "17" public.citext, "18" public.citext)) commentpivotq ON ((expidpivotq.plex_exp_id = commentpivotq.plex_exp_id)));


ALTER TABLE public.v_experiment_plex_members_tsv_entry OWNER TO d3l243;

--
-- Name: TABLE v_experiment_plex_members_tsv_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_plex_members_tsv_entry TO readaccess;

