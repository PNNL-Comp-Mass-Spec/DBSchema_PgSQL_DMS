--
CREATE OR REPLACE PROCEDURE dpkg.update_data_package_eus_info
(
    _dataPackageList text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates EUS-related fields in T_Data_Package for one or more data packages
**      Also updates Instrument_ID
**
**  Arguments:
**    _dataPackageList   '' or 0 to update all data packages, otherwise a comma separated list of data package IDs to update
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _dataPackageCount int;
    _updateCount int
    _firstID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _dataPackageList := Coalesce(_dataPackageList, '');
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Populate a temporary table with the data package IDs to update
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DataPackagesToUpdate (
        ID int not NULL,
        Best_EUS_Proposal_ID text NULL,
        Best_Instrument_Name text NULL,
        Best_EUS_Instrument_ID int NULL
    );

    CREATE INDEX IX_Tmp_DataPackagesToUpdate ON Tmp_DataPackagesToUpdate
    (
        ID ASC
    );

    If _dataPackageList = '' Or _dataPackageList = '0' or _dataPackageList = ',' Then
        INSERT INTO Tmp_DataPackagesToUpdate (data_pkg_id)
        SELECT data_pkg_id
        FROM dpkg.t_data_package;
    Else
        INSERT INTO Tmp_DataPackagesToUpdate (data_pkg_id)
        SELECT data_pkg_id
        FROM dpkg.t_data_package
        WHERE data_pkg_id IN (
                SELECT Value
                FROM public.parse_delimited_integer_list ( _dataPackageList, ',' ) );
    End If;

    SELECT COUNT(*)
    INTO _dataPackageCount
    FROM Tmp_DataPackagesToUpdate;

    If _dataPackageCount = 0 Then
        _message := format('No valid data packages were found in the list: %s', _dataPackageList);
        RAISE INFO '%', _message;

        DROP TABLE Tmp_DataPackagesToUpdate;
        RETURN;
    Else
        If _dataPackageCount > 1 Then
            _message := 'Updating ' || Cast(_dataPackageCount as text) || ' data packages';
        Else

            SELECT ID
            INTO _firstID
            FROM Tmp_DataPackagesToUpdate

            _message := 'Updating data package ' || Cast(_firstID as text);
        End If;

        -- Print _message
    End If;

    ---------------------------------------------------
    -- Update the EUS Person ID of the data package owner
    ---------------------------------------------------

    UPDATE dpkg.t_data_package DP
    SET eus_person_id = EUSUser.eus_person_id
    FROM Tmp_DataPackagesToUpdate Src
         INNER JOIN V_EUS_User_ID_Lookup EUSUser
           ON DP.Owner = EUSUser.Username
    WHERE DP.ID = Src.ID AND
          Coalesce(DP.EUS_Person_ID, '') <> Coalesce(EUSUser.EUS_Person_ID, '');
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
    --
    UPDATE Tmp_DataPackagesToUpdate Target
    SET Best_EUS_Proposal_ID = FilterQ.EUS_Proposal_ID
    FROM ( SELECT RankQ.data_pkg_id,
                  RankQ.EUS_Proposal_ID
           FROM ( SELECT data_pkg_id,
                         EUS_Proposal_ID,
                         ProposalCount,
                         Row_Number() OVER ( Partition By SourceQ.data_pkg_id Order By ProposalCount DESC ) AS CountRank
                  FROM ( SELECT DPD.data_pkg_id,
                                DR.Proposal AS EUS_Proposal_ID,
                                COUNT(*) AS ProposalCount
                         FROM dpkg.t_data_package_datasets DPD
                              INNER JOIN Tmp_DataPackagesToUpdate Src
                                ON DPD.data_pkg_id = Src.ID
                              INNER JOIN V_Dataset_List_Report_2 DR
                                ON DPD.dataset_id = DR.ID
                         WHERE NOT DR.Proposal IS NULL AND NOT DR.Proposal LIKE 'EPR%'
                         GROUP BY DPD.data_pkg_id, DR.Proposal
                       ) SourceQ
                ) RankQ
           WHERE RankQ.CountRank = 1
          ) FilterQ
    WHERE Target.ID = FilterQ.data_pkg_id;

    ---------------------------------------------------
    -- Look for any data packages that have a null Best_EUS_Proposal_ID in Tmp_DataPackagesToUpdate
    -- yet have entries defined in dpkg.t_data_package_eus_proposals
    ---------------------------------------------------
    --
    UPDATE Tmp_DataPackagesToUpdateTarget
    SET Best_EUS_Proposal_ID = FilterQ.Proposal_ID
    FROM ( SELECT data_pkg_id,
                  proposal_id
           FROM ( SELECT data_pkg_id,
                         proposal_id,
                         item_added,
                         Row_Number() OVER ( Partition By data_pkg_id Order By item_added DESC ) AS IdRank
                  FROM dpkg.t_data_package_eus_proposals
                  WHERE (data_pkg_id IN ( SELECT ID
                                          FROM
                                          WHERE Best_EUS_Proposal_ID IS NULL ))
                ) RankQ
           WHERE RankQ.IdRank = 1
         ) FilterQ
    WHERE Target.ID = FilterQ.Data_Package_ID;

    ---------------------------------------------------
    -- Find the most common Instrument used by the datasets associated with each data package
    ---------------------------------------------------
    --
    UPDATE Tmp_DataPackagesToUpdate Target
    SET Best_Instrument_Name = FilterQ.Instrument
    FROM ( SELECT RankQ.data_pkg_id,
                             RankQ.instrument
                      FROM ( SELECT data_pkg_id,
                                    instrument,
                                    InstrumentCount,
                                    Row_Number() OVER ( Partition By SourceQ.data_pkg_id Order By InstrumentCount DESC ) AS CountRank
                             FROM ( SELECT DPD.data_pkg_id,
                                           DPD.instrument,
                                           COUNT(*) AS InstrumentCount
         FROM dpkg.t_data_package_datasets DPD
                                         INNER JOIN Tmp_DataPackagesToUpdate Src
                                           ON DPD.data_pkg_id = Src.ID
                                    WHERE NOT DPD.instrument Is Null
                                    GROUP BY DPD.data_pkg_id, DPD.instrument
                                  ) SourceQ
                           ) RankQ
                      WHERE RankQ.CountRank = 1
                     ) FilterQ
    WHERE Target.ID = FilterQ.data_pkg_id;

    ---------------------------------------------------
    -- Update EUS_Instrument_ID in Tmp_DataPackagesToUpdate
    ---------------------------------------------------
    --
    UPDATE Tmp_DataPackagesToUpdate Target
    SET Best_EUS_Instrument_ID = EUSInst.EUS_Instrument_ID
    FROM V_EUS_Instrument_ID_Lookup EUSInst
    WHERE Target.Best_Instrument_Name = EUSInst.Instrument_Name;

    ---------------------------------------------------
    -- Update EUS Proposal data_pkg_id, eus_instrument_id, and Instrument_ID as necessary
    -- Do not change existing values in dpkg.t_data_package to null values
    ---------------------------------------------------
    --
    UPDATE dpkg.t_data_package DP
    SET eus_proposal_id = Coalesce(Best_EUS_Proposal_ID, eus_proposal_id),
        eus_instrument_id = Coalesce(Best_EUS_Instrument_ID, eus_instrument_id),
        instrument = Coalesce(Best_Instrument_Name, instrument)
    FROM Tmp_DataPackagesToUpdate Src
    WHERE DP.ID = Src.ID AND
          ( Coalesce(DP.EUS_Proposal_ID, '') <> Src.Best_EUS_Proposal_ID OR
            Coalesce(DP.EUS_Instrument_ID, '') <> Src.Best_EUS_Instrument_ID OR
            Coalesce(DP.Instrument, '') <> Src.Best_Instrument_Name
          );
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 And _dataPackageCount > 1 Then
        _message := format('Updated EUS_Proposal_ID, EUS_Instrument_ID, and/or Instrument name for %s %s',
                            _updateCount, public.check_plural(_updateCount, 'data package', 'data packages'));

        CALL public.post_log_entry ('Normal', _message, 'Update_Data_Package_EUS_Info', 'dpkg');
    End If;

END
$$;

COMMENT ON PROCEDURE dpkg.update_data_package_eus_info IS 'UpdateDataPackageEUSInfo';
