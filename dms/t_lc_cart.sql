--
-- Name: t_lc_cart; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_lc_cart (
    cart_id integer NOT NULL,
    cart_name public.citext NOT NULL,
    cart_state_id integer NOT NULL,
    cart_description public.citext,
    created timestamp without time zone
);


ALTER TABLE public.t_lc_cart OWNER TO d3l243;

--
-- Name: TABLE t_lc_cart; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_lc_cart TO readaccess;

