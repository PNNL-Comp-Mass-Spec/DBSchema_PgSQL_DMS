--
-- Name: getdefaultremoteinfoformanager(text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.getdefaultremoteinfoformanager(IN _managername text, INOUT _remoteinfoxml text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Gets the default remote info parameters for the given manager
**      Retrieves parameters using GetManagerParametersWork, so properly retrieves parent group parameters, if any

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
**
*****************************************************/
DECLARE
    _managerID int := 0;
    _message text;
BEGIN

    _remoteInfoXML := '';

    SELECT mgr_id INTO _managerID
    FROM mc.t_mgrs
    WHERE mgr_name = _managerName;

    If Not Found Then
        -- Manager not found; this is not an error
        Return;
    End If;

    -----------------------------------------------
    -- Create the Temp Table to hold the manager parameters
    -----------------------------------------------

    DROP TABLE IF EXISTS Tmp_Mgr_Params;

    CREATE TEMP TABLE Tmp_Mgr_Params (
        mgr_name text NOT NULL,
        param_name text NOT NULL,
        entry_id int NOT NULL,
        type_id int NOT NULL,
        value text NOT NULL,
        mgr_id int NOT NULL,
        comment text NULL,
        last_affected timestamp NULL,
        entered_by text NULL,
        mgr_type_id int NOT NULL,
        ParentParamPointerState int,
        source text NOT NULL
    );

    -- Populate the temporary table with the manager parameters
    CALL GetManagerParametersWork (_managerName, 0, 50, _message => _message);

    If Not Exists ( SELECT value
                    FROM Tmp_Mgr_Params
                    WHERE mgr_name = _managerName And
                          param_name = 'RunJobsRemotely' AND
                          value = 'True' )
       OR
       Not Exists ( SELECT value
                    FROM Tmp_Mgr_Params
                    WHERE mgr_name = _managerName And
                          param_name = 'RemoteHostName' AND
                          char_length(value) > 0 )  Then

        Return;
    End If;

    -- Concatenate together the parameters to build up the XML
    --
    _remoteInfoXML := '';

    SELECT _remoteInfoXML ||
         '<host>' || value || '</host>' INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE (param_name = 'RemoteHostName' And mgr_name = _managerName);

    SELECT _remoteInfoXML ||
         '<user>' || value || '</user>' INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE (param_name = 'RemoteHostUser' And mgr_name = _managerName);

    SELECT _remoteInfoXML ||
         '<dmsPrograms>' || value || '</dmsPrograms>' INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE (param_name = 'RemoteHostDMSProgramsPath' And mgr_name = _managerName);

    SELECT _remoteInfoXML ||
         '<taskQueue>' || value || '</taskQueue>' INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE (param_name = 'RemoteTaskQueuePath' And mgr_name = _managerName);

    SELECT _remoteInfoXML ||
         '<workDir>' || value || '</workDir>' INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE (param_name = 'RemoteWorkDirPath' And mgr_name = _managerName);

    SELECT _remoteInfoXML ||
         '<orgDB>' || value || '</orgDB>' INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE (param_name = 'RemoteOrgDBPath' And mgr_name = _managerName);

    SELECT _remoteInfoXML ||
         '<privateKey>' || public.udf_get_filename(value) || '</privateKey>' INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE (param_name = 'RemoteHostPrivateKeyFile' And mgr_name = _managerName);

    SELECT _remoteInfoXML ||
         '<passphrase>' || public.udf_get_filename(value) || '</passphrase>' INTO _remoteInfoXML
    FROM Tmp_Mgr_Params
    WHERE (param_name = 'RemoteHostPassphraseFile' And mgr_name = _managerName);

END
$$;


ALTER PROCEDURE mc.getdefaultremoteinfoformanager(IN _managername text, INOUT _remoteinfoxml text) OWNER TO d3l243;

--
-- Name: PROCEDURE getdefaultremoteinfoformanager(IN _managername text, INOUT _remoteinfoxml text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.getdefaultremoteinfoformanager(IN _managername text, INOUT _remoteinfoxml text) IS 'GetDefaultRemoteInfoForManager';

