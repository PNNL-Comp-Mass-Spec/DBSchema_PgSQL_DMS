--
CREATE OR REPLACE PROCEDURE public.update_requested_run_factors
(
    _factorList text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
    _callingUser text = '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update requested run factors from input XML list
**
**      _factorList will look like this if it comes from web page https://dms2.pnl.gov/requested_run_factors/param
**                                                             or https://dms2.pnl.gov/requested_run_batch_blocking/grid
**
**      The "type" attribute of the <id> tag defines what the "i" attributes map to
**
**      <id type="Request" />
**      <r i="193911" f="Factor1" v="Aa" />
**      <r i="194113" f="Factor1" v="Bb" />
**      <r i="205898" f="Factor2" v="Aa" />
**      <r i="194113" f="Factor2" v="Bb" />
**
**
**      Second example for web page https://dms2.pnl.gov/requested_run_factors/param
**
**      <id type="Dataset" />
**      <r i="OpSaliva_009_a_7Mar11_Phoenix_11-01-17" f="Factor1" v="Aa" />
**      <r i="OpSaliva_009_b_7Mar11_Phoenix_11-01-20" f="Factor1" v="Bb" />
**      <r i="OpSaliva_009_a_7Mar11_Phoenix_11-01-17" f="Factor2" v="Aa" />
**      <r i="OpSaliva_009_b_7Mar11_Phoenix_11-01-20" f="Factor2" v="Bb" />
**
**
**      XML coming from procedure Make_Automatic_Requested_Run_Factors will look like the following
**      - Here, the identifier is RequestID
**
**      <r i="1197727" f="Actual_Run_Order" v="1" />
**      <r i="1197728" f="Actual_Run_Order" v="2" />
**      <r i="1197725" f="Actual_Run_Order" v="3" />
**      <r i="1197726" f="Actual_Run_Order" v="4" />
**      <r i="1197722" f="Actual_Run_Order" v="5" />
**
**
**      One other supported format uses DatasetID
**      - If any records contain "d" attributes, the "type" attribute of the <id> tag is ignored
**
**      <r d="214536" f="Factor1" v="Aa" />
**      <r d="214003" f="Factor1" v="Bb" />
**      <r d="213522" f="Factor2" v="Aa" />
**
**
**  Arguments:
**    _factorList   XML (see above)
**    _infoOnly     Set to true to preview the changes that would be made
**
**  Auth:   grk
**  Date:   02/20/2010 grk - Initial release
**          03/17/2010 grk - Expanded blacklist
**          03/22/2010 grk - Allow dataset id
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          12/08/2011 mem - Added additional blacklisted factor names: Experiment, Dataset, Name, and Status
**          12/09/2011 mem - Now checking for invalid Requested Run IDs
**          12/15/2011 mem - Added support for the "type" attribute in the <id> tag
**          09/12/2012 mem - Now auto-removing columns Dataset_ID, Dataset, or Experiment if they are present as factor names
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/06/2016 mem - Populate column Last_Updated in T_Factor
**                         - Expand the warning message for unrecognized _idType
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/12/2022 mem - Trim leading and trailing whitespace when storing factors
**          11/11/2022 mem - Trim whitespace when checking for unnamed factors
**          12/13/2022 mem - Ignore factors named 'Dataset ID'
**                         - Rename temp table
**          01/25/2023 mem - Block factors named 'Run_Order'
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _invalidCount int;
    _invalidIDs text;
    _matchCount int;
    _xml AS xml;
    _idType citext;
    _idTypeOriginal text;
    _badFactorNames text := '';
    _invalidRequestIDs text := '';
    _changeSummary text := '';
    _usageMessage text := '';

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
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

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _message := '';
    _returnCode := '';

    If Coalesce(_callingUser, '') = '' Then
        _callingUser := get_user_login_without_domain('');
    End If;

    _infoOnly := Coalesce(_infoOnly, false);

    -- Uncomment to log the XML for debugging purposes
    -- CALL post_log_entry ('Debug', _factorList, 'Update_Requested_Run_Factors');

    -----------------------------------------------------------
    -- Temp table to hold factors
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_FactorInfo (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Identifier citext null,         -- Could be RequestID or DatasetName
        Factor citext null,
        Value citext null,
        DatasetID int null,             -- DatasetID; not always present
        RequestID int null,
        UpdateSkipCode int              -- 0 to update, 1 means unchanged, 2 means invalid factor name
    );

    -----------------------------------------------------------
    -- Convert _factorList to rooted XML
    -----------------------------------------------------------

    _xml := public.try_cast('<root>' || _factorList || '</root>', null::xml);

    If _xml Is Null Then
        _message := 'Factor list is not valid XML';
        RAISE EXCEPTION '%', _message;
    End If;

    -----------------------------------------------------------
    -- Check whether the XML contains <id type="Request" />
    -- Note that this will be ignored if entries like the following exist in the XML:
    --    <r d="214536" f="Factor1" v="Aa" />
    -----------------------------------------------------------

    _idType := (xpath('//root/id/@type', _xml))[1]::text;

    If Coalesce(_idType, '') = '' Then
        -- Assume _idType is RequestID
        _idType := 'RequestID';
    End If;

    _idTypeOriginal := _idType;

    -- Auto-update _idType if needed
    If _idType = 'Request' Then
        _idType := 'RequestID';
    End If;

    If _idType = 'DatasetName' OR _idType Like 'Dataset_Name' OR _idType Like 'Dataset_Num' Then
        _idType := 'Dataset';
    End If;

    -----------------------------------------------------------
    -- Populate temp table with new parameters
    -----------------------------------------------------------

    INSERT INTO Tmp_FactorInfo (Identifier, Factor, Value, DatasetID, UpdateSkipCode)
    SELECT XmlQ.Identifier, XmlQ.Factor, XmlQ.Value, XmlQ.DatasetID, 0
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _xml As rooted_xml
             ) Src,
             XMLTABLE('//root/r'
                      PASSING Src.rooted_xml
                      COLUMNS Identifier text PATH '@i',
                              Factor text PATH '@f',
                              Value text PATH '@v',
                              DatasetID int PATH '@d')        -- Not always defined (XML should either have i=RequestID or d=DatasetID)
         ) XmlQ;


    -----------------------------------------------------------
    -- If table contains DatasetID values, auto-populate the Identifier column with RequestIDs
    -----------------------------------------------------------

    If Exists (SELECT * FROM Tmp_FactorInfo WHERE Not DatasetID IS NULL) Then

        If Exists (SELECT * FROM Tmp_FactorInfo WHERE DatasetID IS NULL) Then
            _message := 'Encountered a mix of XML tag attributes; if using the "d" attribute for DatasetID, all entries must have "d" defined';

            If _infoOnly Then
                -- Show the contents of Tmp_FactorInfo
                CALL public.show_tmp_factor_info();
            End If;

            _returnCode := 'U5116';

            DROP TABLE Tmp_FactorInfo;
            RETURN;
        End If;

        UPDATE Tmp_FactorInfo
        SET Identifier = RR.request_id
        FROM t_requested_run RR
        WHERE Tmp_FactorInfo.dataset_id = RR.dataset_id AND
              Tmp_FactorInfo.Identifier IS NULL;

        -- The identifier column now contains RequestID values
        _idType := 'RequestID';

        If Exists (SELECT * FROM Tmp_FactorInfo WHERE Identifier IS NULL) Then
            _message := 'Unable to resolve Dataset ID to Request ID for one or more entries (Dataset ID not found in requested run table)';

            -- Construct a list of Dataset IDs that are not present in t_requested_run

            SELECT string_agg(DatasetID::text, ', ' ORDER BY DatasetID)
            INTO _invalidIDs
            FROM Tmp_FactorInfo
            WHERE Identifier Is Null;

            _message := format('%s; error with: %s', _message, Coalesce(_invalidIDs, '??'));

            If _infoOnly Then
                -- Show the contents of Tmp_FactorInfo
                CALL public.show_tmp_factor_info();
            End If;

            _returnCode := 'U5117';

            DROP TABLE Tmp_FactorInfo;
            RETURN;
        End If;

    End If;

    -----------------------------------------------------------
    -- Validate _idType
    -----------------------------------------------------------

    If Not _idType IN ('RequestID', 'DatasetID', 'Job', 'Dataset') Then
        _message := format('Identifier type "%s" was not recognized in the header row; should be Request, RequestID, DatasetID, Job, or Dataset (i.e. Dataset Name)',
                           _idTypeOriginal);

        If _infoOnly Then
            -- Show the contents of Tmp_FactorInfo
            CALL public.show_tmp_factor_info();
        End If;

        _returnCode := 'U5118';

        DROP TABLE Tmp_FactorInfo;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Make sure the identifiers are all numeric for certain types
    -----------------------------------------------------------

    If _idType IN ('RequestID', 'DatasetID', 'Job') Then

        SELECT string_agg(Coalesce(Identifier, '<NULL>'), ',' ORDER BY Identifier)
        INTO _invalidIDs
        FROM Tmp_FactorInfo
        WHERE public.try_cast(Identifier, null::int) Is Null;

        If Coalesce(_invalidIDs, '') <> '' Then
            -- One or more entries is non-numeric
            _message := format('Identifier keys must all be integers when Identifier column contains %s; error with: ',
                                _idTypeOriginal, Coalesce(_invalidIDs, '??'));

            If _infoOnly Then
                -- Show the contents of Tmp_FactorInfo
                CALL public.show_tmp_factor_info();
            End If;

            _returnCode := 'U5119';

            DROP TABLE Tmp_FactorInfo;
            RETURN;
        End If;
    End If;

    -----------------------------------------------------------
    -- Populate column RequestID using the Identifier column
    -----------------------------------------------------------

    If _idType = 'RequestID' Then
        -- Identifier is Requestid
        UPDATE Tmp_FactorInfo
        SET RequestID = public.try_cast(Identifier, 0);
    End If;

    If _idType = 'DatasetID' Then
        -- Identifier is DatasetID
        UPDATE Tmp_FactorInfo
        SET RequestID = RR.ID,
            DatasetID = public.try_cast(Tmp_FactorInfo.Identifier, 0)
        FROM t_requested_run RR
        WHERE public.try_cast(Tmp_FactorInfo.Identifier, 0) = RR.dataset_id;

    End If;

    If _idType = 'Dataset' Then
        -- Identifier is Dataset Name
        UPDATE Tmp_FactorInfo
        SET RequestID = RR.ID,
            DatasetID = DS.Dataset_ID
        FROM t_dataset DS
             INNER JOIN t_requested_run RR
               ON RR.dataset_id = DS.dataset_id
        WHERE Tmp_FactorInfo.Identifier = DS.dataset;

    End If;

    If _idType = 'Job' Then
        -- Identifier is Job
        UPDATE Tmp_FactorInfo
        SET RequestID = RR.ID,
            DatasetID = DS.Dataset_ID
        FROM t_analysis_job AJ
             INNER JOIN t_dataset DS
               ON DS.dataset_id = AJ.dataset_id
             INNER JOIN t_requested_run RR
               ON RR.dataset_id = DS.dataset_id
        WHERE public.try_cast(Tmp_FactorInfo.Identifier, 0) = AJ.job;

    End If;

    -----------------------------------------------------------
    -- Check for unresolved requests
    -----------------------------------------------------------

    SELECT COUNT(*)
           SUM(CASE WHEN RequestID IS NULL THEN 1 ELSE 0 END)
    INTO _matchCount, _invalidCount
    FROM ( SELECT DISTINCT Identifier,
                           RequestID
           FROM Tmp_FactorInfo ) InnerQ;

    If _invalidCount > 0 Then
        If _invalidCount = _matchCount And _matchCount = 1 Then
            _message := format('Unable to determine RequestID for the factor');
        ElsIf _invalidCount = _matchCount Then
            _message := format('Unable to determine RequestID for all %s factors', _matchCount);
        Else
            _message := format('Unable to determine RequestID for %s of %s factors', _invalidCount, _matchCount);
        End If;

        _message := format('%s; treating the Identifier column As %s', _message, _idType);

        If _infoOnly Then
            -- Show the contents of Tmp_FactorInfo
            CALL public.show_tmp_factor_info();
        End If;

        _returnCode := 'U5120';

        DROP TABLE Tmp_FactorInfo;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Validate factor names
    -----------------------------------------------------------

    SELECT string_agg(Factor, ', ' ORDER BY Factor)
    INTO _badFactorNames
    FROM ( SELECT DISTINCT Factor
           FROM Tmp_FactorInfo
           WHERE Not Factor::citext In ('Dataset ID')      -- Note that factors named 'Dataset ID' and 'Dataset_ID' are removed later in this procedure
          ) LookupQ
    WHERE Factor SIMILAR TO '%[^0-9A-Za-z_.]%';

    If Coalesce(_badFactorNames, '') <> '' Then
        If char_length(_badFactorNames) < 256 Then
            _message := format('Unacceptable characters in factor names "%s"', _badFactorNames);
        Else
            _message := format('Unacceptable characters in factor names "%s ..."', LEFT(_badFactorNames, 256));
        End If;

        If _infoOnly Then
            -- Show the contents of Tmp_FactorInfo
            CALL public.show_tmp_factor_info();
        End If;

        _returnCode := 'U5127';

        DROP TABLE Tmp_FactorInfo;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Auto-delete data that cannot be a factor
    -- These column names could be present if the user
    -- saved the results of a list report (or of http://dms2.pnl.gov/requested_run_factors/param)
    -- to a text file, then edited the data in Excel, then included the extra columns when copying from Excel
    --
    -- Name is not a valid factor name since it is used to label the Requested Run Name column at http://dms2.pnl.gov/requested_run_factors/param
    -----------------------------------------------------------

    UPDATE Tmp_FactorInfo
    SET UpdateSkipCode = 2
    WHERE Factor::citext IN ('Batch_ID', 'BatchID', 'Experiment', 'Dataset', 'Status', 'Request', 'Name');

    If FOUND And _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        SELECT *, Case When UpdateSkipCode = 2 Then 'Yes' Else 'No' End As AutoSkip_Invalid_Factor
        FROM Tmp_FactorInfo

    End If;

    -----------------------------------------------------------
    -- Make sure factor name is not in blacklist
    --
    -- Note that Javascript code behind http://dms2.pnl.gov/requested_run_factors/param and https://dms2.pnl.gov/requested_run_batch_blocking/grid
    -- should auto-remove factors "Block" and "Run_Order" if it is present
    -----------------------------------------------------------

    _badFactorNames := '';

    SELECT string_agg(Factor, ', ' ORDER BY Factor)
    INTO _badFactorNames
    FROM ( SELECT DISTINCT Factor
           FROM Tmp_FactorInfo
           WHERE Factor::citext IN ('Block', 'Run_Order', 'Run Order', 'Type')
         ) LookupQ;

    If Coalesce(_badFactorNames, '') <> '' Then

        If _badFactorNames Like '%,%' Then
            _message := format('Invalid factor names: %s', _badFactorNames);
        Else
            _message := format('Invalid factor name: %s', _badFactorNames);
        End If;

        If _infoOnly Then
            -- Show the contents of Tmp_FactorInfo
            CALL public.show_tmp_factor_info();
        End If;

        _returnCode := 'U5115';

        DROP TABLE Tmp_FactorInfo;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Auto-remove standard DMS names from the factor table
    -----------------------------------------------------------

    DELETE FROM Tmp_FactorInfo
    WHERE Factor::citext IN ('Dataset_ID', 'Dataset ID', 'Dataset', 'Experiment')

    -----------------------------------------------------------
    -- Check for invalid Request IDs in the factors table
    -----------------------------------------------------------

    SELECT string_agg(RequestID::text, ', ' ORDER BY RequestID)
    INTO _invalidRequestIDs
    FROM Tmp_FactorInfo
         LEFT OUTER JOIN t_requested_run RR
           ON Tmp_FactorInfo.RequestID = RR.request_id
    WHERE Tmp_FactorInfo.UpdateSkipCode = 0 And RR.request_id IS NULL;

    If Coalesce(_invalidRequestIDs, '') <> '' Then

        _message := format('Invalid Requested Run IDs: %s', _invalidRequestIDs);

        If _infoOnly Then
            -- Show the contents of Tmp_FactorInfo
            CALL public.show_tmp_factor_info();
        End If;

        _returnCode := 'U5113';

        DROP TABLE Tmp_FactorInfo;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Flag values that are unchanged
    -----------------------------------------------------------

    UPDATE Tmp_FactorInfo
    SET UpdateSkipCode = 1
    WHERE UpdateSkipCode = 0 AND
          EXISTS ( SELECT *
                   FROM t_factor
                   WHERE t_factor.type = 'Run_Request' AND
                         Tmp_FactorInfo.RequestID = t_factor.target_id AND
                         Tmp_FactorInfo.Factor = t_factor.name AND
                         Tmp_FactorInfo.value = t_factor.value )

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        -- Preview the contents of the Temp table
        SELECT *
        FROM Tmp_FactorInfo
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Remove blank values from factors table
    -----------------------------------------------------------

    DELETE FROM t_factor
    WHERE t_factor.type = 'Run_Request' AND
          EXISTS ( SELECT *
                   FROM Tmp_FactorInfo
                   WHERE UpdateSkipCode = 0 AND
                         Tmp_FactorInfo.RequestID = t_factor.target_id AND
                         Tmp_FactorInfo.Factor = t_factor.name AND
                         Trim(Tmp_FactorInfo.value) = '' );

    -----------------------------------------------------------
    -- Update existing items in factors tables
    -----------------------------------------------------------

    UPDATE t_factor Target
    SET value = Tmp_FactorInfo.value,
        last_updated = CURRENT_TIMESTAMP
    FROM Tmp_FactorInfo Src
    WHERE Src.RequestID = Target.TargetID AND
          Src.Factor = Target.Name AND
          Target.Type = 'Run_Request' AND
          Src.UpdateSkipCode = 0 AND
          Src.Value <> Target.Value;

    -----------------------------------------------------------
    -- Add new factors
    -----------------------------------------------------------

    INSERT INTO t_factor( type,
                          target_id,
                          name,
                          value,
                          last_updated )
    SELECT 'Run_Request' AS Type,
           RequestID AS TargetID,
           Factor AS FactorName,
           value,
           CURRENT_TIMESTAMP
    FROM Tmp_FactorInfo
    WHERE UpdateSkipCode = 0 AND
          Trim(Tmp_FactorInfo.value) <> '' AND
          NOT EXISTS ( SELECT *
                       FROM t_factor
                       WHERE Tmp_FactorInfo.RequestID = t_factor.target_id AND
                             Tmp_FactorInfo.Factor = t_factor.name AND
                             t_factor.type = 'Run_Request' );

    -----------------------------------------------------------
    -- Convert changed items to XML for logging
    -----------------------------------------------------------

    SELECT string_agg(format('<r i="%s" f="%s" v="%s" />', RequestID, Factor, Value), '' ORDER BY RequestID, Factor)
    INTO _changeSummary
    FROM Tmp_FactorInfo
    WHERE UpdateSkipCode = 0;

    -----------------------------------------------------------
    -- Log changes
    -----------------------------------------------------------

    If _changeSummary <> '' Then
        INSERT INTO t_factor_log (changed_by, changes)
        VALUES (_callingUser, _changeSummary);
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := '';
    CALL post_usage_log_entry ('update_requested_run_factors', _usageMessage);

    DROP TABLE Tmp_FactorInfo;
END
$$;

COMMENT ON PROCEDURE public.update_requested_run_factors IS 'UpdateRequestedRunFactors';
