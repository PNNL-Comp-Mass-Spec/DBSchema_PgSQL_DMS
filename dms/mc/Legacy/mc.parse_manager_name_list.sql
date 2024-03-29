--
-- Name: parse_manager_name_list(text, integer, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.parse_manager_name_list(IN _managernamelist text DEFAULT ''::text, IN _removeunknownmanagers integer DEFAULT 1, INOUT _message text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Parse the list of managers in _managerNameList
**      and populate a temporary table with the manager names
**
**      The calling procedure must create a temporary table (the table can contain additional columns)
**        CREATE TEMP TABLE TmpManagerList (
**            manager_name text NOT NULL
**        )
**
**  Arguments:
**    _managerNameList          One or more manager names (comma-separated list); supports wildcards
**    _removeUnknownManagers    When 1, delete manager names that are not defined in _removeUnknownManagers
**    _message                  Status message
**
**  Auth:   mem
**  Date:   05/09/2008
**          05/14/2015 mem - Update Insert query to explicitly list field Manager_Name
**          01/28/2020 mem - Ported to PostgreSQL
**          02/04/2020 mem - Rename manager name column mgr_name
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _managerFilter text;
    _s text;
BEGIN

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------

    _managerNameList       := Trim(Coalesce(_managerNameList, ''));
    _removeUnknownManagers := Coalesce(_removeUnknownManagers, 1);
    _message := '';

    -----------------------------------------------
    -- Creata a temporary table
    -----------------------------------------------

    DROP TABLE IF EXISTS TmpManagerSpecList;

    CREATE TEMP TABLE TmpManagerSpecList (
        entry_id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        manager_name text NOT NULL
    );

    -----------------------------------------------
    -- Parse _managerNameList
    -----------------------------------------------

    If _managerNameList = '' Then
        Return;
    End If;

    -- Populate TmpManagerSpecList with the data in _managerNameList
    INSERT INTO TmpManagerSpecList (manager_name)
    SELECT value
    FROM public.udf_parse_delimited_list(_managerNameList, ',');

    -- Populate TmpManagerList with the entries in TmpManagerSpecList that do not contain a % wildcard
    INSERT INTO TmpManagerList (manager_name)
    SELECT manager_name
    FROM TmpManagerSpecList
    WHERE NOT manager_name SIMILAR TO '%[%]%' AND NOT manager_name SIMILAR TO '%\[%';
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -- Delete the non-wildcard entries from TmpManagerSpecList

    DELETE FROM TmpManagerSpecList target
    WHERE NOT target.manager_name SIMILAR TO '%[%]%' AND NOT manager_name SIMILAR TO '%\[%';
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -- Parse the entries in TmpManagerSpecList (all should have a wildcard)

    For _managerFilter In
        SELECT manager_name
        FROM TmpManagerSpecList
        ORDER BY Entry_ID
    Loop
        _s := format(
                'INSERT INTO TmpManagerList (manager_name) ' ||
                'SELECT mgr_name ' ||
                'FROM mc.t_mgrs ' ||
                'WHERE mgr_name SIMILAR TO $1');

        EXECUTE _s USING _managerFilter;

        _s := regexp_replace(_s, '\$1', '''' || _managerFilter || '''');
        RAISE Info '%', _s;

    End Loop;

    If _removeUnknownManagers = 0 Then
        RETURN;
    End If;

    -- Delete entries from TmpManagerList that are not defined in mc.t_mgrs

    DELETE FROM TmpManagerList
    WHERE NOT manager_name IN (SELECT mgr_name FROM mc.t_mgrs);
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount > 0 Then
        _message := 'Found ' || _myRowCount || ' entries in _managerNameList that are not defined in mc.t_mgrs';
        RAISE INFO '%', _message;

        _message := '';
    End If;

END
$_$;


ALTER PROCEDURE mc.parse_manager_name_list(IN _managernamelist text, IN _removeunknownmanagers integer, INOUT _message text) OWNER TO d3l243;

--
-- Name: PROCEDURE parse_manager_name_list(IN _managernamelist text, IN _removeunknownmanagers integer, INOUT _message text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.parse_manager_name_list(IN _managernamelist text, IN _removeunknownmanagers integer, INOUT _message text) IS 'ParseManagerNameList stored procedure';

