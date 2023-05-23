--
-- Name: parse_manager_name_list(text, integer); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.parse_manager_name_list(_manager_name_list text DEFAULT ''::text, _remove_unknown_managers integer DEFAULT 1) RETURNS TABLE(manager_name public.citext)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Parses the list of managers in _manager_name_list
**      and returns a list of manager names
**
**  Arguments:
**    _manager_name_list        One or more manager names (comma-separated list); supports wildcards
**    _remove_unknown_managers  When 1, delete manager names that are not defined in mc.t_mgrs
**
**  Auth:   mem
**  Date:   05/09/2008
**          05/14/2015 mem - Update Insert query to explicitly list field Manager_Name
**          01/28/2020 mem - Ported to PostgreSQL
**          02/04/2020 mem - Rename manager name column mgr_name
**          02/07/2020 mem - Fix typo in temp table name
**          03/24/2022 mem - Fix typo in comment
**          04/16/2022 mem - Use new function name
**                         - Drop temp table before exiting the procedure
**          08/21/2022 mem - Convert from procedure to function
**                         - Replace temp tables with arrays
**          08/22/2022 mem - Change column manager_name to citext in the returned table
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _managerSpecList citext[];
    _managerList citext[];
    _additionalManagers citext[];
    _managerFilter citext;
    _s text;
    _initialCount int;
    _finalCount int;
BEGIN

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    _manager_name_list := Coalesce(_manager_name_list, '');
    _remove_unknown_managers := Coalesce(_remove_unknown_managers, 1);

    If char_length(_manager_name_list) = 0 Then
        RETURN;
    End If;

    -----------------------------------------------
    -- Parse _manager_name_list
    -----------------------------------------------

    _managerSpecList := ARRAY (
                            SELECT value
                            FROM public.parse_delimited_list(_manager_name_list, ',')
                        );

    -- Populate _managerList with the entries in _managerSpecList that do not contain a % wildcard

    _managerList := ARRAY (
                        SELECT NameQ.manager_name
                        FROM ( SELECT unnest( _managerSpecList ) AS manager_name ) As NameQ
                        WHERE NOT NameQ.manager_name SIMILAR TO '%[%]%' AND NOT NameQ.manager_name SIMILAR TO '%\[%'
                    );

    -- Parse the entries in _managerSpecList that have a wildcard
    --
    For _managerFilter In
        SELECT NameQ.manager_name
        FROM ( SELECT unnest( _managerSpecList ) AS manager_name ) As NameQ
        WHERE NameQ.manager_name SIMILAR TO '%[%]%' OR NameQ.manager_name SIMILAR TO '%\[%'
    Loop
        _s := format(
                'SELECT ARRAY (' ||
                        'SELECT mgr_name ' ||
                        'FROM mc.t_mgrs ' ||
                        'WHERE mgr_name SIMILAR TO $1 )');

        EXECUTE _s
        INTO _additionalManagers
        USING _managerFilter;

        If array_length(_additionalManagers, 1) > 0 Then
            _managerList := array_cat(_managerList, _additionalManagers);
        End If;

        -- Uncomment to debug:
        -- _s := regexp_replace(_s, '\$1', '''' || _managerFilter || '''');
        -- RAISE NOTICE '%', _s;

    End Loop;

    If _remove_unknown_managers = 0 Then
        RETURN QUERY
        SELECT DISTINCT unnest( _managerList );

        RETURN;
    End If;

    -- Remove managers from _managerList that are not defined in mc.t_mgrs
    --
    _initialCount := array_length(_managerList, 1);

    _managerList := ARRAY (
                        SELECT mc.t_mgrs.mgr_name
                        FROM ( SELECT unnest( _managerList ) AS manager_name ) As NameQ
                             INNER JOIN mc.t_mgrs
                               ON NameQ.manager_name::citext = mc.t_mgrs.mgr_name
                    );

    _finalCount := array_length(_managerList, 1);

    If _initialCount > _finalCount Then
        RAISE INFO 'Found % entries in _manager_name_list that are not defined in mc.t_mgrs', _initialCount - _finalCount;
    End If;

    RETURN QUERY
    SELECT DISTINCT unnest( _managerList );
END
$_$;


ALTER FUNCTION mc.parse_manager_name_list(_manager_name_list text, _remove_unknown_managers integer) OWNER TO d3l243;

--
-- Name: FUNCTION parse_manager_name_list(_manager_name_list text, _remove_unknown_managers integer); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON FUNCTION mc.parse_manager_name_list(_manager_name_list text, _remove_unknown_managers integer) IS 'ParseManagerNameList';

