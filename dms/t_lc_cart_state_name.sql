--
-- Name: t_lc_cart_state_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_lc_cart_state_name (
    cart_state_id integer NOT NULL,
    cart_state public.citext
);


ALTER TABLE public.t_lc_cart_state_name OWNER TO d3l243;

--
-- Name: t_lc_cart_state_name pk_t_lc_cart_state; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_cart_state_name
    ADD CONSTRAINT pk_t_lc_cart_state PRIMARY KEY (cart_state_id);

ALTER TABLE public.t_lc_cart_state_name CLUSTER ON pk_t_lc_cart_state;

--
-- Name: TABLE t_lc_cart_state_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_lc_cart_state_name TO readaccess;
GRANT SELECT ON TABLE public.t_lc_cart_state_name TO writeaccess;

