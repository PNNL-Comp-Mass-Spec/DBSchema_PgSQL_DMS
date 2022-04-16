--
-- Name: t_sample_prep_request_items; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sample_prep_request_items (
    prep_request_item_id integer NOT NULL,
    item_id public.citext NOT NULL,
    item_name public.citext,
    item_type public.citext NOT NULL,
    status public.citext,
    created timestamp without time zone,
    item_added timestamp without time zone NOT NULL
);


ALTER TABLE public.t_sample_prep_request_items OWNER TO d3l243;

--
-- Name: TABLE t_sample_prep_request_items; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_prep_request_items TO readaccess;

