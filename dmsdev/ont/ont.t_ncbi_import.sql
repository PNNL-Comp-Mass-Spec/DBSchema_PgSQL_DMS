--
-- Name: t_ncbi_import; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_ncbi_import (
    tax_id integer,
    tax_name public.citext,
    unique_name public.citext,
    name_class public.citext
);


ALTER TABLE ont.t_ncbi_import OWNER TO d3l243;

--
-- Name: TABLE t_ncbi_import; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_ncbi_import TO readaccess;
GRANT SELECT ON TABLE ont.t_ncbi_import TO writeaccess;

