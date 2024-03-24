--
-- Name: update_cached_experiment_component_names(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_experiment_component_names(IN _experimentid integer, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update t_cached_experiment_components, which tracks the semicolon-separated list
**      of biomaterial names and reference compound names for each experiment
**
**  Arguments:
**    _experimentID     Set to 0 to process all experiments, or a positive number to only process the given experiment
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   11/29/2017 mem - Initial version
**          01/04/2018 mem - Now caching reference compounds using the ID_Name field (which is of the form Compound_ID:Compound_Name)
**          11/26/2022 mem - Rename parameter to _biomaterialList
**          07/21/2023 mem - Ported to PostgreSQL
**          07/23/2023 mem - Use new alias names for tables
**          09/07/2023 mem - Align assignment statements
**          03/23/2024 mem - Rename the experiment ID argument to _experimentID
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _biomaterialList text := null;
    _refCompoundList text := null;
    _currentExpID int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _experimentID := Coalesce(_experimentID, 0);
    _infoOnly     := Coalesce(_infoOnly, false);

    If _experimentID > 0 Then

        ------------------------------------------------
        -- Processing a single experiment
        ------------------------------------------------

        SELECT string_agg(B.Biomaterial_Name, '; ' ORDER BY B.Biomaterial_Name)
        INTO _biomaterialList
        FROM t_experiment_biomaterial ExpBiomaterial
             INNER JOIN t_biomaterial B
               ON ExpBiomaterial.Biomaterial_ID = B.Biomaterial_ID
        WHERE ExpBiomaterial.Exp_ID = _experimentID;

        SELECT string_agg(RC.id_name, '; ' ORDER BY RC.id_name)
        INTO _refCompoundList
        FROM t_experiment_reference_compounds ERC
             INNER JOIN t_reference_compound RC
               ON ERC.compound_id = RC.compound_id
        WHERE ERC.exp_id = _experimentID;

        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO 'Experiment ID: %', _experimentID;
            RAISE INFO 'Biomaterials:  %', _biomaterialList;
            RAISE INFO 'Reference Compounds: %', _refCompoundList;
        Else

            MERGE INTO t_cached_experiment_components AS t
            USING ( SELECT _experimentID AS Exp_ID,
                           _biomaterialList AS Biomaterial_List,
                           _refCompoundList AS Reference_Compound_List
                  ) AS s
            ON (t.exp_id = s.exp_id)
            WHEN MATCHED AND
                 (t.Biomaterial_List IS DISTINCT FROM s.Biomaterial_List OR
                  t.reference_compound_list IS DISTINCT FROM s.reference_compound_list) THEN
                UPDATE SET
                    Biomaterial_List = s.Biomaterial_List,
                    reference_compound_list = s.reference_compound_list,
                    last_affected = CURRENT_TIMESTAMP
            WHEN NOT MATCHED THEN
                INSERT(exp_id, Biomaterial_List, reference_compound_list)
                VALUES(s.exp_id, s.Biomaterial_List, s.reference_compound_list);

        End If;

        RETURN;
    End If;

    ------------------------------------------------
    -- Processing all experiments
    -- Populate temporary tables with the data to store
    ------------------------------------------------

    CREATE TEMP TABLE Tmp_ExperimentBiomaterial (
        Exp_ID int NOT NULL,
        Biomaterial_List text NULL,
        Items int NULL
    );

    CREATE TEMP TABLE Tmp_ExperimentRefCompounds (
        Exp_ID int NOT NULL,
        Reference_Compound_List text NULL,
        Items int NULL
    );

    CREATE TEMP TABLE Tmp_AdditionalExperiments (
        Exp_ID int NOT NULL
    );

    CREATE UNIQUE INDEX Tmp_ExperimentBiomaterial_experimentID ON Tmp_ExperimentBiomaterial (Exp_ID);

    CREATE UNIQUE INDEX Tmp_ExperimentRefCompounds_experimentID ON Tmp_ExperimentRefCompounds (Exp_ID);

    CREATE UNIQUE INDEX Tmp_AdditionalExperiments_experimentID ON Tmp_AdditionalExperiments (Exp_ID);

    -- Add mapping info for experiments with only one biomaterial

    INSERT INTO Tmp_ExperimentBiomaterial (Exp_ID, Biomaterial_List, Items)
    SELECT ExpBiomaterial.Exp_ID,
           B.Biomaterial_Name,
           1 AS Items
    FROM t_experiment_biomaterial ExpBiomaterial
         INNER JOIN t_biomaterial B
           ON ExpBiomaterial.Biomaterial_ID = B.Biomaterial_ID
         INNER JOIN ( SELECT Exp_ID
                      FROM t_experiment_biomaterial
                      GROUP BY Exp_ID
                      HAVING COUNT(biomaterial_id) = 1 ) FilterQ
           ON ExpBiomaterial.Exp_ID = FilterQ.Exp_ID;

    -- Add mapping info for experiments with only one reference compound

    INSERT INTO Tmp_ExperimentRefCompounds (exp_id, Reference_Compound_List, Items)
    SELECT ERC.exp_id,
           RC.id_name,
           1 AS Items
    FROM t_experiment_reference_compounds ERC
         INNER JOIN t_reference_compound RC
           ON ERC.compound_id = RC.compound_id
         INNER JOIN ( SELECT exp_id
                      FROM t_experiment_reference_compounds
                      GROUP BY exp_id
                      HAVING COUNT(compound_id) = 1 ) FilterQ
           ON ERC.exp_id = FilterQ.exp_id;

    -- Add experiments with multiple biomaterial itesm

    TRUNCATE TABLE Tmp_AdditionalExperiments;

    INSERT INTO Tmp_AdditionalExperiments (Exp_ID)
    SELECT Exp_ID
    FROM t_experiment_biomaterial
    GROUP BY Exp_ID
    HAVING COUNT(biomaterial_id) > 1;

    FOR _currentExpID IN
        SELECT Exp_ID
        FROM Tmp_AdditionalExperiments
        ORDER BY Exp_ID
    LOOP

        SELECT string_agg(B.Biomaterial_Name, '; ' ORDER BY B.Biomaterial_Name)
        INTO _biomaterialList
        FROM t_experiment_biomaterial ExpBiomaterial
            INNER JOIN t_biomaterial B
            ON ExpBiomaterial.Biomaterial_ID = B.Biomaterial_ID
        WHERE ExpBiomaterial.Exp_ID = _currentExpID;

        _matchCount := array_length(string_to_array(_biomaterialList, ';'), 1);

        INSERT INTO Tmp_ExperimentBiomaterial (Exp_ID, Biomaterial_List, Items)
        SELECT _currentExpID, _biomaterialList, _matchCount;

    END LOOP;

    -- Add experiments with multiple reference compounds

    TRUNCATE TABLE Tmp_AdditionalExperiments;

    INSERT INTO Tmp_AdditionalExperiments (Exp_ID)
    SELECT Exp_ID
    FROM t_experiment_reference_compounds
    GROUP BY Exp_ID
    HAVING COUNT(compound_id) > 1;

    FOR _currentExpID IN
        SELECT Exp_ID
        FROM Tmp_AdditionalExperiments
        ORDER BY Exp_ID
    LOOP

        SELECT string_agg(RC.id_name, '; ' ORDER BY RC.id_name)
        INTO _refCompoundList
        FROM t_experiment_reference_compounds ERC
             INNER JOIN t_reference_compound RC
               ON ERC.compound_id = RC.compound_id
        WHERE ERC.exp_id = _currentExpID;

        _matchCount := array_length(string_to_array(_refCompoundList, ';'), 1);

        INSERT INTO Tmp_ExperimentRefCompounds (Exp_ID, Reference_Compound_List, Items)
        SELECT _currentExpID, _refCompoundList, _matchCount;

    END LOOP;

    If _infoOnly Then

        ------------------------------------------------
        -- Preview the data that would be merged into t_cached_experiment_components
        ------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-9s %-40s %-17s %-40s %-24s';

        _infoHead := format(_formatSpecifier,
                            'Exp_ID',
                            'Biomaterial_List',
                            'Biomaterial_Count',
                            'Reference_Compound_List',
                            'Reference_Compound_Count'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '----------------------------------------',
                                     '-----------------',
                                     '----------------------------------------',
                                     '------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        -- Show the first 20 items

        FOR _previewData IN
            SELECT ExpBiomaterial.Exp_ID,
                   ExpBiomaterial.Biomaterial_List,
                   ExpBiomaterial.Items AS Biomaterial_Count,
                   ERC.Reference_Compound_List,
                   ERC.Items AS Reference_Compound_Count
            FROM Tmp_ExperimentBiomaterial ExpBiomaterial
                 FULL OUTER JOIN Tmp_ExperimentRefCompounds ERC
                   ON ExpBiomaterial.Exp_ID = ERC.Exp_ID
            ORDER BY Coalesce(ExpBiomaterial.Items, ERC.Items), Exp_ID
            LIMIT 20
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Exp_ID,
                                _previewData.Biomaterial_List,
                                _previewData.Biomaterial_Count,
                                _previewData.Reference_Compound_List,
                                _previewData.Reference_Compound_Count
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else
        ------------------------------------------------
        -- Update biomaterial lists
        ------------------------------------------------

        MERGE INTO t_cached_experiment_components AS t
        USING ( SELECT exp_id, Biomaterial_List
                FROM Tmp_ExperimentBiomaterial
              ) AS s
        ON (t.exp_id = s.exp_id)
        WHEN MATCHED AND t.Biomaterial_List IS DISTINCT FROM s.Biomaterial_List THEN
            UPDATE SET
                Biomaterial_List = s.Biomaterial_List,
                last_affected = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT(exp_id, Biomaterial_List)
            VALUES(s.exp_id, s.Biomaterial_List);

        ------------------------------------------------
        -- Update reference compound lists
        ------------------------------------------------

        MERGE INTO t_cached_experiment_components AS t
        USING ( SELECT exp_id, reference_compound_list
                FROM Tmp_ExperimentRefCompounds
              ) AS s
        ON (t.exp_id = s.exp_id)
        WHEN MATCHED AND t.reference_compound_list IS DISTINCT FROM s.reference_compound_list THEN
            UPDATE SET
                reference_compound_list = s.reference_compound_list,
                last_affected = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT(exp_id, reference_compound_list)
            VALUES(s.exp_id, s.reference_compound_list);

        ------------------------------------------------
        -- Assure that Biomaterial_List and Reference_Compound_List are Null for experiments not in the temp tables
        ------------------------------------------------

        UPDATE t_cached_experiment_components Target
        SET Biomaterial_List = NULL
        WHERE NOT EXISTS ( SELECT 1
                           FROM Tmp_ExperimentBiomaterial Src
                           WHERE Target.Exp_ID = Src.Exp_ID) AND
              NOT Target.Biomaterial_List IS NULL;

        UPDATE t_cached_experiment_components Target
        SET Reference_Compound_List = NULL
        WHERE NOT EXISTS ( SELECT 1
                           FROM Tmp_ExperimentRefCompounds Src
                           WHERE Target.Exp_ID = Src.Exp_ID) AND
              NOT Target.Reference_Compound_List IS NULL;
    End If;

    DROP TABLE Tmp_ExperimentBiomaterial;
    DROP TABLE Tmp_ExperimentRefCompounds;
    DROP TABLE Tmp_AdditionalExperiments;
END
$$;


ALTER PROCEDURE public.update_cached_experiment_component_names(IN _experimentid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_experiment_component_names(IN _experimentid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_cached_experiment_component_names(IN _experimentid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateCachedExperimentComponentNames';

