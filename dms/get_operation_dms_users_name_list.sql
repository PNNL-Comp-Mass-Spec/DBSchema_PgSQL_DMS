--
-- Name: get_operation_dms_users_name_list(integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_operation_dms_users_name_list(_operationid integer, _formatastable integer DEFAULT 0) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**  	Builds delimited list of DMS users for the given Operation
**
**  Return value: list of users delimited by either semicolons or vertical bars and colons
**
**  Arguments:
**    _formatAsTable   When 0, separate usernames with semicolons.  When 1, include a vertical bar between each user and use a colon between the user's name and network login
**
**  Auth:   jds
**  Date:   12/11/2006 jds - Initial version
**          06/28/2010 ??? - Now limiting to active users
**          12/08/2014 mem - Now using name_with_username to obtain each user's name and username
**          11/17/2016 mem - Add parameter _formatAsTable
**                         - Also change parameter _operationID to an integer
**          08/24/2018 mem - Tabs to spaces
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          05/24/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    _formatAsTable := Coalesce(_formatAsTable, 0);

    If _formatAsTable = 1 Then
        SELECT string_agg(format('%s:%s', U.name, U.username), '|' ORDER BY U.name)
        INTO _result
        FROM T_User_Operations_Permissions O
             INNER JOIN T_Users U
               ON O.user_id = U.user_id
        WHERE O.operation_id = _operationID AND
              U.status = 'Active';
    Else
        SELECT string_agg(U.name_with_username, '; ' ORDER BY U.name)
        INTO _result
        FROM T_User_Operations_Permissions O
             INNER JOIN T_Users U
               ON O.user_id = U.user_id
        WHERE O.operation_id = _operationID AND
              U.status = 'Active';
    End If;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_operation_dms_users_name_list(_operationid integer, _formatastable integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_operation_dms_users_name_list(_operationid integer, _formatastable integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_operation_dms_users_name_list(_operationid integer, _formatastable integer) IS 'GetOperationDMSUsersNameList';

