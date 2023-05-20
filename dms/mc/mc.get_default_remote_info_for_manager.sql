--
-- Name: get_default_remote_info_for_manager(text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.get_default_remote_info_for_manager(IN _managername text, INOUT _remoteinfoxml text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Gets the default remote info parameters for the given manager
**      Retrieves parameters using get_manager_parameters_work, so properly retrieves parent group parameters, if any

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
**          03/14/2018 mem - Use GetManagerParametersWork to lookup manager parameters, allowing for getting remote info parameters from parent groups
**          03/29/2018 mem - Return an empty string if the manager does not have parameters RunJobsRemotely and RemoteHostName defined, or if RunJobsRemotely is false
**          02/05/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling GetManagerParametersWork
**          04/02/2022 mem - Use new procedure name
**                         - Use case insensitive matching of manager name
**          04/16/2022 mem - Use new function name
**          02/01/2023 mem - Rename columns in temporary table
**          05/07/2023 mem - Remove unused variable
**          05/19/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _managerID int := 0;
    _message text;
BEGIN

    _remoteInfoXML := '';

    SELECT mgr_id INTO _managerID
    FROM mc.t_mgrs
    WHERE mgr_name = _managerName::citext;

    If Not Found Then
        -- Manager not found; this is not an error
        Return;
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
    Call mc.get_manager_parameters_work (_managerName, 0, 50, _message => _message);

    If Not Exists ( SELECT value
                    FROM Tmp_Mgr_Params
                    WHERE mgr_name::citext = _managerName::citext And
                          param_name = 'RunJobsRemotely' AND
                          value = 'True' )
       OR
       Not Exists ( SELECT value
                    FROM Tmp_Mgr_Params
                    WHERE mgr_name::citext = _managerName::citext And
                          param_name = 'RemoteHostName' AND
                          char_length(value) > 0 )  Then

        RAISE Warning 'Manager % does not have RunJobsRemotely=True or does not have RemoteHostName defined', _managerName;

        Drop Table Tmp_Mgr_Params;
        Return;
    End If;

    -- Concatenate together the parameters to build up the XML
    --
    _remoteInfoXML := '';

    SELECT format('%s<host>%s</host>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteHostName' And mgr_name::citext = _managerName::citext;

    SELECT format('%s<user>%s</user>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteHostUser' And mgr_name::citext = _managerName::citext;

    SELECT format('%s<dmsPrograms>%s</dmsPrograms>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteHostDMSProgramsPath' And mgr_name::citext = _managerName::citext;

    SELECT format('%s<taskQueue>%s</taskQueue>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteTaskQueuePath' And mgr_name::citext = _managerName::citext;

    SELECT format('%s<workDir>%s</workDir>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteWorkDirPath' And mgr_name::citext = _managerName::citext;

    SELECT format('%s<orgDB>%s</orgDB>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteOrgDBPath' And mgr_name::citext = _managerName::citext;

    SELECT format('%s<privateKey>%s</privateKey>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteHostPrivateKeyFile' And mgr_name::citext = _managerName::citext;

    SELECT format('%s<passphrase>%s</passphrase>', _remoteInfoXML, value)
    INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE param_name = 'RemoteHostPassphraseFile' And mgr_name::citext = _managerName::citext;

    DROP TABLE Tmp_Mgr_Params;

END
$$;


ALTER PROCEDURE mc.get_default_remote_info_for_manager(IN _managername text, INOUT _remoteinfoxml text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_default_remote_info_for_manager(IN _managername text, INOUT _remoteinfoxml text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.get_default_remote_info_for_manager(IN _managername text, INOUT _remoteinfoxml text) IS 'GetDefaultRemoteInfoForManager';

