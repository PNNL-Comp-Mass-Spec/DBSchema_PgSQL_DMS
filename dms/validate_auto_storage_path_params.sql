--
-- Name: validate_auto_storage_path_params(boolean, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.validate_auto_storage_path_params(IN _autodefinestoragepath boolean, IN _autospvolnameclient text, IN _autospvolnameserver text, IN _autosppathroot text, IN _autosparchiveservername text, IN _autosparchivepathroot text, IN _autosparchivesharepathroot text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validate that the auto storage path parameters are correct
**      Raise an exception if there is a problem
**
**  Arguments:
**    _autoDefineStoragePath        When true, storage paths are auto-defined for the given instrument
**    _autoSPVolNameClient          Storage server name,                                     e.g. \\proto-8\
**    _autoSPVolNameServer          Drive letter on storage server (local to server itself), e.g. F:\
**    _autoSPPathRoot               Storage path (share name) on storage server,             e.g. Lumos01\
**    _autoSPArchiveServerName      Archive server name           (validated, but obsolete), e.g. agate.emsl.pnl.gov
**    _autoSPArchivePathRoot        Storage path on EMSL archive  (validated, but obsolete), e.g. /archive/dmsarch/Lumos01
**    _autoSPArchiveSharePathRoot   Archive share path            (validated, but obsolete), e.g. \\agate.emsl.pnl.gov\dmsarch\Lumos01
**
**  Auth:   mem
**  Date:   05/13/2011 mem - Initial version
**          07/05/2016 mem - Archive path is now aurora.emsl.pnl.gov\archive\dmsarch\
**          09/02/2016 mem - Archive path is now adms.emsl.pnl.gov\dmsarch\
**          09/08/2020 mem - When _autoDefineStoragePath is true, raise an error if any of the paths are \ or /
**          10/05/2023 mem - Archive path is now \\agate.emsl.pnl.gov\dmsarch\  (only used for accessing files added to the archive before MyEMSL)
**                         - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    _autoDefineStoragePath      := Coalesce(_autoDefineStoragePath, false);
    _autoSPVolNameClient        := Trim(Coalesce(_autoSPVolNameClient, ''));
    _autoSPVolNameServer        := Trim(Coalesce(_autoSPVolNameServer, ''));
    _autoSPPathRoot             := Trim(Coalesce(_autoSPPathRoot, ''));
    _autoSPArchiveServerName    := Trim(Coalesce(_autoSPArchiveServerName, ''));
    _autoSPArchivePathRoot      := Trim(Coalesce(_autoSPArchivePathRoot, ''));
    _autoSPArchiveSharePathRoot := Trim(Coalesce(_autoSPArchiveSharePathRoot, ''));

    If _autoDefineStoragePath Then
        If _autoSPVolNameClient In ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage VolNameClient cannot be blank or \ or /';
        End If;
        If _autoSPVolNameServer In ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage VolNameServer cannot be blank or \ or /';
        End If;
        If _autoSPPathRoot In ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage Path Root cannot be blank or \ or /';
        End If;
        If _autoSPArchiveServerName In ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage Archive Server Name cannot be blank or \ or /';
        End If;
        If _autoSPArchivePathRoot In ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage Archive Path Root cannot be blank or \ or /';
        End If;
        If _autoSPArchiveSharePathRoot In ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage Archive Share Path Root cannot be blank or \ or /';
        End If;
    End If;

    If _autoSPVolNameClient <> '' Then
        If _autoSPVolNameClient Not Like '\\\\%' Then
            RAISE EXCEPTION 'Auto Storage VolNameClient should be a network share, for example: \\Proto-3\';
        End If;

        If _autoSPVolNameClient Not Like '%\\' Then
            RAISE EXCEPTION 'Auto Storage VolNameClient must end in a backslash, for example: \\Proto-3\';
        End If;
    End If;

    If _autoSPVolNameServer <> '' Then
        If _autoSPVolNameServer::citext Not SIMILAR TO '[A-Z]:%' Then
            RAISE EXCEPTION 'Auto Storage VolNameServer should be a drive letter, for example: G:\';
        End If;

        If _autoSPVolNameServer Not Like '%\\' Then
            RAISE EXCEPTION 'Auto Storage VolNameServer must end in a backslash, for example: G:\';
        End If;
    End If;

    If _autoSPArchivePathRoot <> '' Then
        If _autoSPArchivePathRoot Not Like '/%' Then
            RAISE EXCEPTION 'Auto Storage Archive Path Root should be a Linux path, for example: /archive/dmsarch/VOrbiETD01';
        End If;

    End If;

    If _autoSPArchiveSharePathRoot <> '' Then
        If _autoSPArchiveSharePathRoot Not Like '\\\\%' Then
            RAISE EXCEPTION 'Auto Storage Archive Share Path Root should be a network share, for example: \\agate.emsl.pnl.gov\dmsarch\VOrbiETD01';
        End If;
    End If;

END
$$;


ALTER PROCEDURE public.validate_auto_storage_path_params(IN _autodefinestoragepath boolean, IN _autospvolnameclient text, IN _autospvolnameserver text, IN _autosppathroot text, IN _autosparchiveservername text, IN _autosparchivepathroot text, IN _autosparchivesharepathroot text) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_auto_storage_path_params(IN _autodefinestoragepath boolean, IN _autospvolnameclient text, IN _autospvolnameserver text, IN _autosppathroot text, IN _autosparchiveservername text, IN _autosparchivepathroot text, IN _autosparchivesharepathroot text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.validate_auto_storage_path_params(IN _autodefinestoragepath boolean, IN _autospvolnameclient text, IN _autospvolnameserver text, IN _autosppathroot text, IN _autosparchiveservername text, IN _autosparchivepathroot text, IN _autosparchivesharepathroot text) IS 'ValidateAutoStoragePathParams';

