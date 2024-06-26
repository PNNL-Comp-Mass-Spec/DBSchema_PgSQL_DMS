--
-- Name: get_default_remote_info_for_manager(text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.get_default_remote_info_for_manager(IN _managername text, INOUT _remoteinfoxml text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get the default remote info parameters for the given manager
**      Retrieves parameters using mc.get_manager_parameters_work, so properly retrieves parent group parameters, if any
**
**      If the manager does not have parameters RunJobsRemotely and RemoteHostName defined, returns an empty string
**      Also returns an empty string if RunJobsRemotely is not True
**
**      Example value for _remoteInfoXML
**      <host>prismweb2</host><user>svc-dms</user><taskQueue>/file1/temp/DMSTasks</taskQueue><workDir>/file1/temp/DMSWorkDir</workDir><orgDB>/file1/temp/DMSOrgDBs</orgDB><privateKey>Svc-Dms.key</privateKey><passphrase>Svc-Dms.pass</passphrase>
**
**  Arguments:
**    _managerName     Manager name
**    _remoteInfoXML   Output XML if valid remote info parameters are defined, otherwise an empty string
**
**  Auth:   mem
**  Date:   05/18/2017 mem - Initial version
**          03/14/2018 mem - Use Get_Manager_Parameters_Work to lookup manager parameters, allowing for getting remote info parameters from parent groups
**          03/29/2018 mem - Return an empty string if the manager does not have parameters RunJobsRemotely and RemoteHostName defined, or if RunJobsRemotely is false
**          02/05/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling Get_Manager_Parameters_Work
**          04/02/2022 mem - Use new procedure name
**                         - Use case insensitive matching of manager name
**          04/16/2022 mem - Use new function name
**          02/01/2023 mem - Rename columns in temporary table
**          05/07/2023 mem - Remove unused variable
**          05/19/2023 mem - Use format() for string concatenation
**          06/09/2023 mem - Move to the sw schema
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _managerID int := 0;
    _message text;
BEGIN

    _remoteInfoXML := '';

    SELECT mgr_id
    INTO _managerID
    FROM mc.t_mgrs
    WHERE mgr_name = _managerName::citext;

    If Not Found Then
        -- Manager not found; this is not an error
        RETURN;
    End If;

    -----------------------------------------------
    -- Create the Temp Table to hold the manager parameters
    -----------------------------------------------

    CREATE TEMP TABLE Tmp_Mgr_Params (
        mgr_name text NOT NULL,
        param_name text NOT NULL,
        entry_id int NOT NULL,
        param_type_id int NOT NULL,
        value text NOT NULL,
        mgr_id int NOT NULL,
        comment text NULL,
        last_affected timestamp NULL,
        entered_by text NULL,
        mgr_type_id int NOT NULL,
        Parent_Param_Pointer_State int,
        source text NOT NULL
    );

    -- Populate the temporary table with the manager parameters
    CALL mc.get_manager_parameters_work(_managerName, 0, 50, _message => _message);

    If Not Exists (SELECT value
                   FROM Tmp_Mgr_Params
                   WHERE mgr_name::citext = _managerName::citext AND
                         param_name = 'RunJobsRemotely' AND
                         value = 'True' )
       OR
       Not Exists (SELECT value
                   FROM Tmp_Mgr_Params
                   WHERE mgr_name::citext = _managerName::citext AND
                         param_name = 'RemoteHostName' AND
                         Coalesce(value, '') <> '')
    Then
        RAISE WARNING 'Manager % does not have RunJobsRemotely=True or does not have RemoteHostName defined', _managerName;

        DROP TABLE Tmp_Mgr_Params;
        RETURN;
    End If;

    -- Concatenate together the parameters to build up the XML

    _remoteInfoXML := '';

    SELECT format('%s<host>%s</host>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteHostName' AND mgr_name::citext = _managerName::citext;

    SELECT format('%s<user>%s</user>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteHostUser' AND mgr_name::citext = _managerName::citext;

    SELECT format('%s<dmsPrograms>%s</dmsPrograms>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteHostDMSProgramsPath' AND mgr_name::citext = _managerName::citext;

    SELECT format('%s<taskQueue>%s</taskQueue>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteTaskQueuePath' AND mgr_name::citext = _managerName::citext;

    SELECT format('%s<workDir>%s</workDir>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteWorkDirPath' AND mgr_name::citext = _managerName::citext;

    SELECT format('%s<orgDB>%s</orgDB>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteOrgDBPath' AND mgr_name::citext = _managerName::citext;

    SELECT format('%s<privateKey>%s</privateKey>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteHostPrivateKeyFile' AND mgr_name::citext = _managerName::citext;

    SELECT format('%s<passphrase>%s</passphrase>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteHostPassphraseFile' AND mgr_name::citext = _managerName::citext;

    DROP TABLE Tmp_Mgr_Params;
END
$$;


ALTER PROCEDURE sw.get_default_remote_info_for_manager(IN _managername text, INOUT _remoteinfoxml text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_default_remote_info_for_manager(IN _managername text, INOUT _remoteinfoxml text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.get_default_remote_info_for_manager(IN _managername text, INOUT _remoteinfoxml text) IS 'GetDefaultRemoteInfoForManager';

