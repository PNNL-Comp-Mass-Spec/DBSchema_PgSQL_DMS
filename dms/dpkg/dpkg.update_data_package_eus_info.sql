--
-- Name: update_data_package_eus_info(text, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.update_data_package_eus_info(IN _datapackagelist text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update EUS-related fields in T_Data_Package for one or more data packages
**      Also update Instrument_ID
**
**  Arguments:
**    _dataPackageList  Comma-separated list of data package IDs to update; use '' or '0' to update all data packages
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   10/18/2016 mem - Initial version
**          10/19/2016 mem - Replace parameter _dataPackageID with _dataPackageList
**          11/04/2016 mem - Exclude proposals that start with EPR
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/07/2017 mem - Now updating Instrument and EUS_Instrument_ID
**          03/07/2018 mem - Properly handle null values for Best_EUS_Proposal_ID, Best_EUS_Instrument_ID, and Best_Instrument_Name
**          05/18/2022 mem - Use new EUS Proposal column name
**          06/08/2022 mem - Use new Item_Added column name
**          08/14/2023 mem - Ported to PostgreSQL
**          09/28/2023 mem - Obtain dataset names and instrument names from t_dataset and t_instrument_name
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _dataPackageCount int;
    _updateCount int;
    _firstID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _dataPackageList := Trim(Coalesce(_dataPackageList, ''));

    ---------------------------------------------------
    -- Populate a temporary table with the data package IDs to update
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DataPackagesToUpdate (
        Data_Pkg_ID int NOT NULL,
        Best_EUS_Proposal_ID text NULL,
        Best_Instrument_Name text NULL,
        Best_EUS_Instrument_ID int NULL
    );

    CREATE INDEX IX_Tmp_DataPackagesToUpdate ON Tmp_DataPackagesToUpdate
    (
        Data_Pkg_ID ASC
    );

    If _dataPackageList = '' Or _dataPackageList = '0' or _dataPackageList = ',' Then
        INSERT INTO Tmp_DataPackagesToUpdate (data_pkg_id)
        SELECT data_pkg_id
        FROM dpkg.t_data_package;
    Else
        INSERT INTO Tmp_DataPackagesToUpdate (data_pkg_id)
        SELECT data_pkg_id
        FROM dpkg.t_data_package
        WHERE data_pkg_id IN (SELECT Value
                              FROM public.parse_delimited_integer_list(_dataPackageList)
                             );
    End If;

    SELECT COUNT(*)
    INTO _dataPackageCount
    FROM Tmp_DataPackagesToUpdate;

    If _dataPackageCount = 0 Then
        _message := format('No valid data packages were found in the list: %s', _dataPackageList);
        RAISE WARNING '%', _message;

        DROP TABLE Tmp_DataPackagesToUpdate;
        RETURN;
    End If;

    If _dataPackageCount > 1 Then
        _message := format('Updating %s data packages', _dataPackageCount);
    Else
        SELECT Data_Pkg_ID
        INTO _firstID
        FROM Tmp_DataPackagesToUpdate;

        _message := format('Updating data package %s', _firstID);
    End If;

    -- RAISE INFO '%', _message

    ---------------------------------------------------
    -- Update the EUS Person ID of the data package owner
    ---------------------------------------------------

    UPDATE dpkg.t_data_package DP
    SET eus_person_id = EUSUser.eus_person_id
    FROM public.V_EUS_User_ID_Lookup EUSUser
    WHERE DP.data_pkg_id IN (SELECT Data_Pkg_ID FROM Tmp_DataPackagesToUpdate) AND
          DP.owner_username = EUSUser.Username AND
          DP.EUS_Person_ID IS DISTINCT FROM EUSUser.EUS_Person_ID;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 And _dataPackageCount > 1 Then
        _message := format('Updated EUS_Person_ID for %s %s',
                            _updateCount, public.check_plural(_updateCount, 'data package', 'data packages'));

        CALL public.post_log_entry ('Normal', _message, 'Update_Data_Package_EUS_Info', 'dpkg');
    End If;

    ---------------------------------------------------
    -- Find the most common EUS proposal used by the datasets associated with each data package
    -- Exclude proposals that start with EPR since those are not official EUS proposals
    ---------------------------------------------------

    UPDATE Tmp_DataPackagesToUpdate Target
    SET Best_EUS_Proposal_ID = FilterQ.EUS_Proposal_ID
    FROM (SELECT RankQ.data_pkg_id,
                 RankQ.EUS_Proposal_ID
          FROM (SELECT data_pkg_id,
                       EUS_Proposal_ID,
                       Proposal_Count,
                       Row_Number() OVER (PARTITION BY SourceQ.data_pkg_id ORDER BY Proposal_Count DESC) AS CountRank
                FROM (SELECT DPD.data_pkg_id,
                             RR.EUS_Proposal_ID,           -- EUS Proposal ID (stored as text since typically an integer, but could be 'EPR56820')
                             COUNT(RR.EUS_Proposal_ID) AS Proposal_Count
                      FROM dpkg.t_data_package_datasets DPD
                           INNER JOIN Tmp_DataPackagesToUpdate Src
                             ON DPD.data_pkg_id = Src.Data_Pkg_ID
                           INNER JOIN public.t_dataset DS
                             ON DPD.dataset_id = DS.dataset_id
                           LEFT OUTER JOIN public.t_requested_run RR
                             ON DS.dataset_id = RR.dataset_id
                      WHERE NOT RR.EUS_Proposal_ID IS NULL AND NOT RR.EUS_Proposal_ID LIKE 'EPR%'
                      GROUP BY DPD.data_pkg_id, RR.EUS_Proposal_ID
                     ) SourceQ
               ) RankQ
          WHERE RankQ.CountRank = 1
         ) FilterQ
    WHERE Target.Data_Pkg_ID = FilterQ.data_pkg_id;

    ---------------------------------------------------
    -- Look for any data packages that have a null Best_EUS_Proposal_ID in Tmp_DataPackagesToUpdate,
    -- yet have entries defined in dpkg.t_data_package_eus_proposals
    ---------------------------------------------------

    UPDATE Tmp_DataPackagesToUpdate Target
    SET Best_EUS_Proposal_ID = FilterQ.Proposal_ID
    FROM (SELECT data_pkg_id,
                 proposal_id
          FROM (SELECT data_pkg_id,
                       proposal_id,
                       item_added,
                       Row_Number() OVER (PARTITION BY data_pkg_id ORDER BY item_added DESC) AS IdRank
                FROM dpkg.t_data_package_eus_proposals
                WHERE data_pkg_id IN (SELECT Data_Pkg_ID
                                      FROM Tmp_DataPackagesToUpdate
                                      WHERE Best_EUS_Proposal_ID IS NULL)
               ) RankQ
          WHERE RankQ.IdRank = 1
         ) FilterQ
    WHERE Target.Data_Pkg_ID = FilterQ.data_pkg_id;

    ---------------------------------------------------
    -- Find the most common Instrument used by the datasets associated with each data package
    ---------------------------------------------------

    UPDATE Tmp_DataPackagesToUpdate Target
    SET Best_Instrument_Name = FilterQ.Instrument
    FROM (SELECT RankQ.data_pkg_id,
                 RankQ.instrument
          FROM (SELECT data_pkg_id,
                       instrument,
                       InstrumentCount,
                       Row_Number() OVER (PARTITION BY SourceQ.data_pkg_id ORDER BY InstrumentCount DESC) AS CountRank
                FROM (SELECT DPD.data_pkg_id,
                             InstName.Instrument AS Instrument,
                             COUNT(InstName.Instrument) AS InstrumentCount
                      FROM dpkg.t_data_package_datasets DPD
                           INNER JOIN public.t_dataset DS
                             ON DPD.Dataset_ID = DS.Dataset_ID
                           INNER JOIN public.t_instrument_name InstName
                             ON DS.instrument_id = InstName.instrument_id
                           INNER JOIN Tmp_DataPackagesToUpdate Src
                             ON DPD.data_pkg_id = Src.Data_Pkg_ID
                      WHERE NOT InstName.Instrument IS NULL
                      GROUP BY DPD.data_pkg_id, InstName.Instrument
                     ) SourceQ
               ) RankQ
          WHERE RankQ.CountRank = 1
         ) FilterQ
    WHERE Target.Data_Pkg_ID = FilterQ.data_pkg_id;

    ---------------------------------------------------
    -- Update EUS_Instrument_ID in Tmp_DataPackagesToUpdate
    ---------------------------------------------------

    UPDATE Tmp_DataPackagesToUpdate Target
    SET Best_EUS_Instrument_ID = EUSInst.EUS_Instrument_ID
    FROM public.V_EUS_Instrument_ID_Lookup EUSInst
    WHERE Target.Best_Instrument_Name = EUSInst.Instrument_Name;

    ---------------------------------------------------
    -- Update EUS Proposal data_pkg_id, eus_instrument_id, and Instrument_ID as necessary
    -- Do not change existing values in dpkg.t_data_package to null values
    ---------------------------------------------------

    UPDATE dpkg.t_data_package DP
    SET eus_proposal_id   = Coalesce(Best_EUS_Proposal_ID,   eus_proposal_id),
        eus_instrument_id = Coalesce(Best_EUS_Instrument_ID, eus_instrument_id),
        instrument        = Coalesce(Best_Instrument_Name,   instrument)
    FROM Tmp_DataPackagesToUpdate Src
    WHERE DP.data_pkg_id = Src.Data_Pkg_ID AND
          (Coalesce(DP.EUS_Proposal_ID, '') <> Src.Best_EUS_Proposal_ID OR
           NOT Src.Best_EUS_Instrument_ID IS NULL AND DP.EUS_Instrument_ID IS DISTINCT FROM Src.Best_EUS_Instrument_ID OR
           Coalesce(DP.Instrument, '') <> Src.Best_Instrument_Name
          );
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 And _dataPackageCount > 1 Then
        _message := format('Updated EUS_Proposal_ID, EUS_Instrument_ID, and/or Instrument name for %s %s',
                            _updateCount, public.check_plural(_updateCount, 'data package', 'data packages'));

        CALL public.post_log_entry ('Normal', _message, 'Update_Data_Package_EUS_Info', 'dpkg');
    End If;

    DROP TABLE Tmp_DataPackagesToUpdate;
END
$$;


ALTER PROCEDURE dpkg.update_data_package_eus_info(IN _datapackagelist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_data_package_eus_info(IN _datapackagelist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.update_data_package_eus_info(IN _datapackagelist text, INOUT _message text, INOUT _returncode text) IS 'UpdateDataPackageEUSInfo';

