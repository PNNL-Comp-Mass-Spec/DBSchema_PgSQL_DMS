--
-- Name: t_user_operations_permissions; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_user_operations_permissions (
    user_id integer NOT NULL,
    operation_id integer NOT NULL
);


ALTER TABLE public.t_user_operations_permissions OWNER TO d3l243;

--
-- Name: t_user_operations_permissions pk_t_user_operations_permissions; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_user_operations_permissions
    ADD CONSTRAINT pk_t_user_operations_permissions PRIMARY KEY (user_id, operation_id);

--
-- Name: t_user_operations_permissions fk_t_user_operations_permissions_t_user_operations; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_user_operations_permissions
    ADD CONSTRAINT fk_t_user_operations_permissions_t_user_operations FOREIGN KEY (operation_id) REFERENCES public.t_user_operations(operation_id);

--
-- Name: t_user_operations_permissions fk_t_user_operations_permissions_t_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_user_operations_permissions
    ADD CONSTRAINT fk_t_user_operations_permissions_t_users FOREIGN KEY (user_id) REFERENCES public.t_users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: TABLE t_user_operations_permissions; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_user_operations_permissions TO readaccess;
GRANT SELECT ON TABLE public.t_user_operations_permissions TO writeaccess;

