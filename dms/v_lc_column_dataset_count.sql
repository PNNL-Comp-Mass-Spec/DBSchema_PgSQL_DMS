--
-- Name: v_lc_column_dataset_count; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_column_dataset_count AS
 SELECT lc.lc_column AS column_number,
    statename.column_state AS state,
    count(ds.dataset_id) AS number_of_datasets
   FROM ((public.t_dataset ds
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     JOIN public.t_lc_column_state_name statename ON ((lc.column_state_id = statename.column_state_id)))
  GROUP BY lc.lc_column, statename.column_state;


ALTER TABLE public.v_lc_column_dataset_count OWNER TO d3l243;

--
-- Name: TABLE v_lc_column_dataset_count; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_column_dataset_count TO readaccess;

