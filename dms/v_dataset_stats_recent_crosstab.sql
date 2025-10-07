--
-- Name: v_dataset_stats_recent_crosstab; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_stats_recent_crosstab AS
 SELECT state,
    dataset_state,
    COALESCE("Agilent_Ion_Trap", 0) AS "Agilent_Ion_Trap",
    COALESCE("Agilent_TOF_V2", 0) AS "Agilent_TOF_V2",
    COALESCE("BrukerFT_BAF", 0) AS "BrukerFT_BAF",
    COALESCE("BrukerMALDI_Imaging_V2", 0) AS "BrukerMALDI_Imaging_V2",
    COALESCE("Data_Folders", 0) AS "Data_Folders",
    COALESCE("Finnigan_Ion_Trap", 0) AS "Finnigan_Ion_Trap",
    COALESCE("GC_QExactive", 0) AS "GC_QExactive",
    COALESCE("IMS_Agilent_TOF_DotD", 0) AS "IMS_Agilent_TOF_DotD",
    COALESCE("IMS_Agilent_TOF_UIMF", 0) AS "IMS_Agilent_TOF_UIMF",
    COALESCE("LTQ_FT", 0) AS "LTQ_FT",
    COALESCE("Triple_Quad", 0) AS "Triple_Quad",
    COALESCE("Waters_IMS", 0) AS "Waters_IMS",
    COALESCE("Waters_TOF", 0) AS "Waters_TOF"
   FROM public.crosstab('SELECT DSN.Dataset_state_ID AS state,
              DSN.dataset_state,
              Instrument.instrument_class,
              COUNT(DS.dataset_id) AS Dataset_Count
     FROM public.t_dataset DS
          INNER JOIN public.t_dataset_state_name DSN
            ON DS.dataset_state_id = DSN.Dataset_state_ID
          INNER JOIN public.t_instrument_name Instrument
            ON DS.instrument_id = Instrument.Instrument_ID
     WHERE (DS.last_affected >= CURRENT_TIMESTAMP - Interval ''1 month'')
     GROUP BY DSN.Dataset_state_ID, DSN.dataset_state, Instrument.instrument_class
     ORDER BY DSN.dataset_state, Instrument.instrument_class'::text, 'SELECT unnest(''{Agilent_Ion_Trap,Agilent_TOF_V2,
                     BrukerFT_BAF,BrukerMALDI_Imaging_V2,
                     Data_Folders,Finnigan_Ion_Trap,GC_QExactive,
                     IMS_Agilent_TOF_DotD,IMS_Agilent_TOF_UIMF,
                     LTQ_FT,Triple_Quad,
                     Waters_IMS,Waters_TOF}''::text[])'::text) pivotdata(state integer, dataset_state public.citext, "Agilent_Ion_Trap" integer, "Agilent_TOF_V2" integer, "BrukerFT_BAF" integer, "BrukerMALDI_Imaging_V2" integer, "Data_Folders" integer, "Finnigan_Ion_Trap" integer, "GC_QExactive" integer, "IMS_Agilent_TOF_DotD" integer, "IMS_Agilent_TOF_UIMF" integer, "LTQ_FT" integer, "Triple_Quad" integer, "Waters_IMS" integer, "Waters_TOF" integer);


ALTER VIEW public.v_dataset_stats_recent_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_dataset_stats_recent_crosstab; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_stats_recent_crosstab TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_stats_recent_crosstab TO writeaccess;

