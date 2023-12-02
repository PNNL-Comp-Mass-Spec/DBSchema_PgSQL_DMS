--
-- Name: v_statistics_dataset_captures_by_day; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_statistics_dataset_captures_by_day AS
 SELECT EXTRACT(year FROM ds.created) AS year,
    EXTRACT(month FROM ds.created) AS month,
    EXTRACT(day FROM ds.created) AS day,
    (ds.created)::date AS date,
    count(ds.dataset_id) AS datasets_created
   FROM (public.t_dataset ds
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
  WHERE ((instname.instrument OPERATOR(public.!~~) 'External%'::public.citext) AND (instname.instrument OPERATOR(public.!~~) 'Broad%'::public.citext) AND (instname.instrument OPERATOR(public.!~~) 'FHCRC%'::public.citext))
  GROUP BY (EXTRACT(year FROM ds.created)), (EXTRACT(month FROM ds.created)), (EXTRACT(day FROM ds.created)), ((ds.created)::date);


ALTER VIEW public.v_statistics_dataset_captures_by_day OWNER TO d3l243;

--
-- Name: TABLE v_statistics_dataset_captures_by_day; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_statistics_dataset_captures_by_day TO readaccess;
GRANT SELECT ON TABLE public.v_statistics_dataset_captures_by_day TO writeaccess;

