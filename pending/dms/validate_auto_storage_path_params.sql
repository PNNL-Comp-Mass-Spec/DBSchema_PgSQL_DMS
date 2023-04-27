--
CREATE OR REPLACE PROCEDURE public.validate_auto_storage_path_params
(
    _autoDefineStoragePath boolean,
    _autoSPVolNameClient text,
    _autoSPVolNameServer text,
    _autoSPPathRoot text,
    _autoSPArchiveServerName text,
    _autoSPArchivePathRoot text,
    _autoSPArchiveSharePathRoot text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Validates that the Auto storage path parameters are correct
**
**  Returns: The storage path ID; 0 if an error
**
**  Auth:   mem
**  Date:   05/13/2011 mem - Initial version
**          07/05/2016 mem - Archive path is now aurora.emsl.pnl.gov\archive\dmsarch\
**          09/02/2016 mem - Archive path is now adms.emsl.pnl.gov\dmsarch\
**          09/08/2020 mem - When _autoDefineStoragePath is true, raise an error if any of the paths are \ or /
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    _autoSPVolNameClient := Trim(Coalesce(_autoSPVolNameClient, ''));
    _autoSPVolNameServer := Trim(Coalesce(_autoSPVolNameServer, ''));
    _autoSPPathRoot := Trim(Coalesce(_autoSPPathRoot, ''));
    _autoSPArchiveServerName := Trim(Coalesce(_autoSPArchiveServerName, ''));
    _autoSPArchivePathRoot := Trim(Coalesce(_autoSPArchivePathRoot, ''));
    _autoSPArchiveSharePathRoot := Trim(Coalesce(_autoSPArchiveSharePathRoot, ''));

    If _autoDefineStoragePath Then
        If _autoSPVolNameClient IN ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage VolNameClient cannot be blank or \ or /';
        End If;
        If _autoSPVolNameServer IN ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage VolNameServer cannot be blank or \ or /';
        End If;
        If _autoSPPathRoot IN ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage Path Root cannot be blank or \ or /';
        End If;
        If _autoSPArchiveServerName IN ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage Archive Server Name cannot be blank or \ or /';
        End If;
        If _autoSPArchivePathRoot IN ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage Archive Path Root cannot be blank or \ or /';
        End If;
        If _autoSPArchiveSharePathRoot IN ('', '\', '/') Then
            RAISE EXCEPTION 'Auto Storage Archive Share Path Root cannot be blank or \ or /';
        End If;
    End If;

    If _autoSPVolNameClient <> '' Then
        If _autoSPVolNameClient Not Like '\\%' Then
            RAISE EXCEPTION 'Auto Storage VolNameClient should be a network share, for example: \\Proto-3\';
        End If;

        If _autoSPVolNameClient Not Like '%\' Then
            RAISE EXCEPTION 'Auto Storage VolNameClient must end in a backslash, for example: \\Proto-3\';
        End If;
    End If;

    If _autoSPVolNameServer <> '' Then
        If _autoSPVolNameServer Not SIMILAR TO '[A-Z]:%' Then
            RAISE EXCEPTION 'Auto Storage VolNameServer should be a drive letter, for example: G:\';
        End If;

        If _autoSPVolNameServer Not Like '%\' Then
            RAISE EXCEPTION 'Auto Storage VolNameServer must end in a backslash, for example: G:\';
        End If;
    End If;

    If _autoSPArchivePathRoot <> '' Then
        If _autoSPArchivePathRoot Not Like '/%' Then
            RAISE EXCEPTION 'Auto Storage Archive Path Root should be a linux path, for example: /archive/dmsarch/Broad_Orb1';
        End If;

    End If;

    If _autoSPArchiveSharePathRoot <> '' Then
        If _autoSPArchiveSharePathRoot Not Like '\\%' Then
            RAISE EXCEPTION 'Auto Storage Archive Share Path Root should be a network share, for example: \\adms.emsl.pnl.gov\dmsarch\VOrbiETD01';
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE public.validate_auto_storage_path_params IS 'ValidateAutoStoragePathParams';
