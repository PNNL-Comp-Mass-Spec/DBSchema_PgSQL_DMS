--
-- Name: t_lc_cart_state_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_lc_cart_state_name (
    cart_state_id integer NOT NULL,
    cart_state public.citext
);


ALTER TABLE public.t_lc_cart_state_name OWNER TO d3l243;

--
-- Name: TABLE t_lc_cart_state_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_lc_cart_state_name TO readaccess;

