--
CREATE OR REPLACE PROCEDURE public.update_cached_experiment_component_names
(
    _expID int,
    _infoOnly boolean = false,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates T_Cached_Experiment_Components,
**      which tracks the semicolon separated list of
**      biomaterial names and reference compound names for each exeriment
**
**  Arguments:
**    _expID   Set to 0 to process all experiments, or a positive number to only process the given experiment
**
**  Auth:   mem
**  Date:   11/29/2017 mem - Initial version
**          01/04/2018 mem - Now caching reference compounds using the ID_Name field (which is of the form Compound_ID:Compound_Name)
**          11/26/2022 mem - Rename parameter to _biomaterialList
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _biomaterialList text := null;
    _refCompoundList text := null;
    _currentExpID int;
    _continue boolean;
BEGIN
    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    _expID := Coalesce(_expID, 0);
    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';

    If _expID > 0 Then
    -- <SingleExperiment>

        ------------------------------------------------
        -- Processing a single experiment
        ------------------------------------------------
        --
        SELECT string_agg(CC.Biomaterial_Name, '; ')
        INTO _biomaterialList
        FROM T_Experiment_Biomaterial ECC
             INNER JOIN T_Biomaterial CC
               ON ECC.Biomaterial_ID = CC.Biomaterial_ID
        WHERE ECC.Exp_ID = _expID
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        SELECT string_agg(RC.id_name, '; ')
        INTO _refCompoundList
        FROM t_experiment_reference_compounds ERC
             INNER JOIN t_reference_compound RC
               ON ERC.compound_id = RC.compound_id
        WHERE ERC.exp_id = _expID
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _infoOnly Then
            RAISE INFO 'Experiment ID: %', _expID;
            RAISE INFO 'Biomaterials:  %', _biomaterialList;
            RAISE INFO 'Reference Compounds: %', _refCompoundList;
        Else

            MERGE INTO t_cached_experiment_components AS t
            USING ( SELECT _expID AS Exp_ID,
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

    Else
    -- <AllExperiments>
        ------------------------------------------------
        -- Processing all experiments
        -- Populate temporary tables with the data to store
        ------------------------------------------------
        --

        CREATE TEMP TABLE Tmp_ExperimentBiomaterial (
            Exp_ID int not null,
            Biomaterial_List text null,
            Items int null
        );

        CREATE TEMP TABLE Tmp_ExperimentRefCompounds (
            Exp_ID int not null,
            Reference_Compound_List text null,
            Items int null
        );

        CREATE TEMP TABLE Tmp_AdditionalExperiments (
            Exp_ID int not null
        );

        CREATE UNIQUE INDEX Tmp_ExperimentBiomaterial_ExpID ON Tmp_ExperimentBiomaterial (Exp_ID);

        CREATE UNIQUE INDEX Tmp_ExperimentRefCompounds_ExpID ON Tmp_ExperimentRefCompounds (Exp_ID);

        CREATE UNIQUE INDEX Tmp_AdditionalExperiments_ExpID ON Tmp_AdditionalExperiments (Exp_ID);

        -- Add mapping info for experiments with only one biomaterial
        --
        INSERT INTO Tmp_ExperimentBiomaterial (Exp_ID, Biomaterial_List, Items)
        SELECT ECC.Exp_ID,
               CC.Biomaterial_Name,
               1 as Items
        FROM T_Experiment_Biomaterial ECC
             INNER JOIN T_Biomaterial CC
               ON ECC.Biomaterial_ID = CC.Biomaterial_ID
             INNER JOIN ( SELECT Exp_ID
                          FROM T_Experiment_Biomaterial
                          GROUP BY Exp_ID
                          HAVING COUNT(*) = 1 ) FilterQ
               ON ECC.Exp_ID = FilterQ.Exp_ID;

        -- Add mapping info for experiments with only one reference compound
        --
        INSERT INTO Tmp_ExperimentRefCompounds (exp_id, Reference_Compound_List, Items)
        SELECT ERC.exp_id,
               RC.id_name,
               1 as Items
        FROM t_experiment_reference_compounds ERC
             INNER JOIN t_reference_compound RC
               ON ERC.compound_id = RC.compound_id
             INNER JOIN ( SELECT exp_id
                          FROM t_experiment_reference_compounds
                          GROUP BY exp_id
                          HAVING COUNT(*) = 1 ) FilterQ
               ON ERC.exp_id = FilterQ.exp_id;

        -- Add experiments with multiple biomaterial itesm
        --
        TRUNCATE TABLE Tmp_AdditionalExperiments;

        INSERT INTO Tmp_AdditionalExperiments (Exp_ID)
        SELECT Exp_ID
        FROM T_Experiment_Biomaterial
        GROUP BY Exp_ID
        HAVING COUNT(*) > 1;

        _currentExpID := 0;
        _continue := true;

        WHILE _continue
        LOOP
            -- This While loop can probably be converted to a For loop; for example:
            --    FOR _itemName IN
            --        SELECT item_name
            --        FROM TmpSourceTable
            --        ORDER BY entry_id
            --    LOOP
            --        ...
            --    END LOOP


            SELECT Exp_ID INTO _currentExpID
            FROM Tmp_AdditionalExperiments
            WHERE Exp_ID > _currentExpID
            ORDER BY Exp_ID
            LIMIT 1;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount = 0 Then
                _continue := false;
            Else
                _biomaterialList := null;

                SELECT string_agg(CC.Biomaterial_Name, '; ')
                INTO _biomaterialList
                FROM T_Experiment_Biomaterial ECC
                    INNER JOIN T_Biomaterial CC
                    ON ECC.Biomaterial_ID = CC.Biomaterial_ID
                WHERE ECC.Exp_ID = _currentExpID
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                INSERT INTO Tmp_ExperimentBiomaterial (Exp_ID, Biomaterial_List, Items)
                SELECT _currentExpID, _biomaterialList, _myRowCount;

            End If;

        END LOOP;

        -- Add experiments with multiple reference compounds
        --
        TRUNCATE TABLE Tmp_AdditionalExperiments;

        INSERT INTO Tmp_AdditionalExperiments (exp_id)
        SELECT exp_id
        FROM t_experiment_reference_compounds
        GROUP BY exp_id
        HAVING COUNT(*) > 1;

        _currentExpID := 0;
        _continue := true;

        WHILE _continue
        LOOP
            -- This While loop can probably be converted to a For loop; for example:
            --    FOR _itemName IN
            --        SELECT item_name
            --        FROM TmpSourceTable
            --        ORDER BY entry_id
            --    LOOP
            --        ...
            --    END LOOP


            SELECT Exp_ID INTO _currentExpID
            FROM Tmp_AdditionalExperiments
            WHERE Exp_ID > _currentExpID
            ORDER BY Exp_ID
            LIMIT 1;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount = 0 Then
                _continue := false;
            Else
                _refCompoundList := null;

                SELECT string_agg(RC.id_name, '; ')
                INTO _refCompoundList
                FROM t_experiment_reference_compounds ERC
                     INNER JOIN t_reference_compound RC
                       ON ERC.compound_id = RC.compound_id
                WHERE ERC.exp_id = _currentExpID;
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                INSERT INTO Tmp_ExperimentRefCompounds (Exp_ID, Reference_Compound_List, Items)
                SELECT _currentExpID, _refCompoundList, _myRowCount

            End If;
        END LOOP;

        If _infoOnly Then
            ------------------------------------------------
            -- Preview the data that would be merged into t_cached_experiment_components
            ------------------------------------------------
            --

            -- ToDo: Show this data using RAISE INFO

            SELECT ECC.Exp_ID,
                   ECC.Biomaterial_List,
                   ECC.Items AS CellCulture_Items,
                   ERC.Reference_Compound_List,
                   ERC.Items AS RefCompound_Items
            FROM Tmp_ExperimentBiomaterial ECC
              FULL OUTER JOIN Tmp_ExperimentRefCompounds ERC
                   ON ECC.Exp_ID = ERC.Exp_ID
            ORDER BY Coalesce(ECC.Items, ERC.Items), Exp_ID;

        Else
            ------------------------------------------------
            -- Update biomaterial lists
            ------------------------------------------------
            --
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
            --
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
            -- Assure Biomaterial_List and Reference_Compound_List are Null for experiments not in the temp tables
            ------------------------------------------------
            --
            UPDATE t_cached_experiment_components
            SET Biomaterial_List = NULL
            FROM t_cached_experiment_components Target

            /********************************************************************************
            ** This UPDATE query includes the target table name in the FROM clause
            ** The WHERE clause needs to have a self join to the target table, for example:
            **   UPDATE t_cached_experiment_components
            **   SET ...
            **   FROM source
            **   WHERE source.id = t_cached_experiment_components.id;
            ********************************************************************************/

                                   ToDo: Fix this query

                 LEFT OUTER JOIN Tmp_ExperimentBiomaterial Src
                   ON Target.Exp_ID = Src.Exp_ID
            WHERE NOT Target.Biomaterial_List IS NULL AND
                  Src.Exp_ID IS NULL

            UPDATE t_cached_experiment_components
            SET reference_compound_list = NULL
            FROM t_cached_experiment_components Target

            /********************************************************************************
            ** This UPDATE query includes the target table name in the FROM clause
            ** The WHERE clause needs to have a self join to the target table, for example:
            **   UPDATE t_cached_experiment_components
            **   SET ...
            **   FROM source
            **   WHERE source.id = t_cached_experiment_components.id;
            ********************************************************************************/

                                   ToDo: Fix this query

                 LEFT OUTER JOIN Tmp_ExperimentRefCompounds Src
                   ON Target.Exp_ID = Src.Exp_ID
            WHERE NOT Target.Reference_Compound_List IS NULL AND
                  Src.Exp_ID IS NULL

        End If;

    End If; -- </AllExperiments>

    DROP TABLE Tmp_ExperimentBiomaterial;
    DROP TABLE Tmp_ExperimentRefCompounds;
    DROP TABLE Tmp_AdditionalExperiments;
END
$$;

COMMENT ON PROCEDURE public.update_cached_experiment_component_names IS 'UpdateCachedExperimentComponentNames';
