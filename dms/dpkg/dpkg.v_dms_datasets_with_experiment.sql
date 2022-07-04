--
-- Name: v_dms_datasets_with_experiment; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_dms_datasets_with_experiment AS
 SELECT ds.dataset_id,
    ds.dataset,
    ds.exp_id,
    e.experiment
   FROM (public.t_dataset ds
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)));


ALTER TABLE dpkg.v_dms_datasets_with_experiment OWNER TO d3l243;

