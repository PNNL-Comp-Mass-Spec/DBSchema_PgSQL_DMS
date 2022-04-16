--
-- Name: t_requested_run_batches; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_batches (
    batch_id integer NOT NULL,
    batch public.citext NOT NULL,
    description public.citext,
    owner integer,
    created timestamp without time zone NOT NULL,
    locked public.citext NOT NULL,
    last_ordered timestamp without time zone,
    requested_batch_priority public.citext NOT NULL,
    actual_batch_priority public.citext NOT NULL,
    requested_completion_date timestamp without time zone,
    justification_for_high_priority public.citext,
    comment public.citext,
    requested_instrument public.citext NOT NULL,
    hex_id public.citext GENERATED ALWAYS AS ("left"((encode(((batch_id)::text)::bytea, 'hex'::text) || '000000000000000000000000'::text), 24)) STORED
);


ALTER TABLE public.t_requested_run_batches OWNER TO d3l243;

--
-- Name: TABLE t_requested_run_batches; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_batches TO readaccess;

