--
-- Name: get_user_operations_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_user_operations_list(_userid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Builds delimited list of Operations for given DMS User
**
**  Return value: comma separated list
**
**  Auth:   jds
**  Date:   12/13/2006
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(U.Operation, ', ' ORDER BY U.Operation)
    INTO _result
    FROM t_user_operations_permissions O
         JOIN t_user_operations U
           ON O.operation_id = U.operation_id
    WHERE O.user_id = _userID;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_user_operations_list(_userid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_user_operations_list(_userid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_user_operations_list(_userid integer) IS 'GetUserOperationsList';

