--
-- Name: v_request_count_by_day; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_request_count_by_day AS
 SELECT make_date(groupq.y, groupq.m, groupq.d) AS date,
    groupq.request,
    groupq.history,
    groupq.total,
    groupq.datasets
   FROM ( SELECT countq.y,
            countq.m,
            countq.d,
            sum(countq.request) AS request,
            sum(countq.history) AS history,
            sum((countq.request + countq.history)) AS total,
            sum(countq.datasets) AS datasets
           FROM ( SELECT (EXTRACT(year FROM rr.created))::integer AS y,
                    (EXTRACT(month FROM rr.created))::integer AS m,
                    (EXTRACT(day FROM rr.created))::integer AS d,
                    sum(
                        CASE
                            WHEN (rr.dataset_id IS NULL) THEN 1
                            ELSE 0
                        END) AS request,
                    sum(
                        CASE
                            WHEN (rr.dataset_id IS NULL) THEN 0
                            ELSE 1
                        END) AS history,
                    0 AS datasets
                   FROM public.t_requested_run rr
                  GROUP BY (EXTRACT(year FROM rr.created)), (EXTRACT(month FROM rr.created)), (EXTRACT(day FROM rr.created))
                UNION
                 SELECT (EXTRACT(year FROM rr.created))::integer AS y,
                    (EXTRACT(month FROM rr.created))::integer AS m,
                    (EXTRACT(day FROM rr.created))::integer AS d,
                    0 AS request,
                    0 AS history,
                    count(*) AS datasets
                   FROM (public.t_requested_run rr
                     JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
                  GROUP BY (EXTRACT(year FROM rr.created)), (EXTRACT(month FROM rr.created)), (EXTRACT(day FROM rr.created))) countq
          GROUP BY countq.y, countq.m, countq.d) groupq;


ALTER TABLE public.v_request_count_by_day OWNER TO d3l243;

--
-- Name: TABLE v_request_count_by_day; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_request_count_by_day TO readaccess;

