--
-- Name: t_sample_submission; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sample_submission (
    submission_id integer NOT NULL,
    campaign_id integer NOT NULL,
    received_by_user_id integer NOT NULL,
    container_list public.citext,
    description public.citext,
    storage_path integer,
    created timestamp without time zone NOT NULL
);


ALTER TABLE public.t_sample_submission OWNER TO d3l243;

--
-- Name: TABLE t_sample_submission; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_submission TO readaccess;

