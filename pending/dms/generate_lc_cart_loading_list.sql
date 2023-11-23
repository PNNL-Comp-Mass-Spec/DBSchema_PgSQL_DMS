--
CREATE OR REPLACE FUNCTION public.generate_lc_cart_loading_list
(
    _lcCartName text,
    _blanksFollowingRequests text,
    _columnsWithLeadingBlanks text
)
RETURNS TABLE
(
	"sequence" int4,
	"name" citext,
	request int4,
	column_number int4,
	experiment citext,
	priority int2,
	"type" citext,
	batch int4,
	block int4,
	run_order int4,
	emsl_usage_type citext,
	emsl_proposal_id citext,
	emsl_users_list citext
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Generates a sample loading list for given LC Cart
**
**      This function is likely unused in 2022, since cart_column in t_requested_run has only had null values since September 2020
**
**      SELECT Extract(year from Entered) AS RR_Year,
**             Sum(CASE WHEN NOT Cart_Column IS NULL THEN 1 ELSE 0 END) AS Requests_with_Non_Null_Cart_Col,
**             Sum(CASE WHEN     Cart_Column > 1     THEN 1 ELSE 0 END) AS Requests_with_Cart_Col_Over_One
**      FROM T_Requested_Run
**      GROUP BY RR_Year
**      ORDER BY RR_Year DESC
**
**  Arguments:
**    _lcCartName
**    _blanksFollowingRequests
**    _columnsWithLeadingBlanks
**
**  Auth:   grk
**  Date:   04/09/2007 (Ticket #424)
**          04/16/2007 grk - Added priority as highest sort attribute
**          06/07/2007 grk - Added EMSL user columns to output (Ticket #488)
**          07/31/2007 mem - Now returning Dataset Type for each request (Ticket #505)
**          08/27/2007 grk - Add ability to start columns with a blank (Ticket #517)
**          09/17/2009 grk - Added check for requests that don't have column assignments
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _col int;
    _numCols int;
    _maxSamples int;
    _qLen int;
    _padCnt int;
    _c int;
    _maxOS int;
    _matchCount int;
    _requestCountTotal int;
    _dsTypeForBlanks text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Create temporary table to hold requested runs
    -- assigned to cart
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_XR (
        request int NOT NULL,
        col int NULL,
        os int PRIMARY KEY GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 2)
    );

    ---------------------------------------------------
    -- Populate temporary table with run requests
    -- assigned to this cart
    ---------------------------------------------------

    INSERT INTO Tmp_XR( request, col )
    SELECT t_requested_run.request_id,
           t_requested_run.cart_column
    FROM t_requested_run
         INNER JOIN t_lc_cart
           ON t_requested_run.cart_id = t_lc_cart.cart_id
    WHERE t_lc_cart.cart_name = _lcCartName
    ORDER BY t_requested_run.priority DESC,
             t_requested_run.batch_id,
             t_requested_run.run_order,
             t_requested_run.request_id

    ---------------------------------------------------
    -- Verify that all requests have column assignments
    ---------------------------------------------------

    If Exists (SELECT request FROM Tmp_XR WHERE col IS NULL) Then
        _message := 'Some requests do not have column assignments';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        DROP TABLE Tmp_XR;
        RETURN;
    End If;

    ---------------------------------------------------
    -- How many columns need to be used for this cart?
    ---------------------------------------------------

    SELECT COUNT(DISTINCT col)
    INTO _numCols
    FROM Tmp_XR;

    ---------------------------------------------------
    -- Add following blanks to table
    ---------------------------------------------------
    -- Use OVERRIDING SYSTEM VALUE to insert an explicit value for the identity column, for example:
    --
    -- INSERT INTO mc.t_log_entries (entry_id, posted_by, posting_time, type, message)
    -- OVERRIDING SYSTEM VALUE
    -- VALUES (12345, 'Test', CURRENT_TIMESTAMP, 'Test', 'message');

    If _blanksFollowingRequests <> '' Then
        --
        INSERT INTO Tmp_XR (request, col, os)
        OVERRIDING SYSTEM VALUE
        SELECT 0, col, os + 1
        FROM Tmp_XR
        WHERE request in (SELECT value FROM public.parse_delimited_integer_list(_blanksFollowingRequests))
    End If;

    ---------------------------------------------------
    -- Add column lead blanks to table
    ---------------------------------------------------

    If _columnsWithLeadingBlanks <> '' Then
        --
        INSERT INTO Tmp_XR (request, col, os)
        OVERRIDING SYSTEM VALUE
        SELECT 0, value, 0 - value
        FROM public.parse_delimited_integer_list(_columnsWithLeadingBlanks);
    End If;

    ---------------------------------------------------
    -- Pad out ends of column queues with blanks
    ---------------------------------------------------

    -- How many samples in longest column queue?
    --

    SELECT MAX(T.X)
    INTO _maxSamples
    FROM ( SELECT COUNT(request) AS X
           FROM Tmp_XR
           GROUP BY col ) T

    _col := 1;

    SELECT MAX(os)
    INTO _maxOS
    FROM Tmp_XR

    --
    WHILE _col <= _numCols
    LOOP
        -- How many samples in col queue?
        --
        SELECT COUNT(request)
        INTO _qLen
        FROM Tmp_XR
        WHERE col = _col;

        -- Number of blanks to add
        --
        _padCnt := _maxSamples - _qLen;

        -- Append blanks
        --
        _c := 0;

        WHILE _c < _padCnt
        LOOP
            INSERT INTO Tmp_XR (request, col, os)
            VALUES (0, _col, _maxOS + 1)
            _maxOS := _maxOS + 1;

            _c := _c + 1;
        END LOOP;

        _col := _col + 1;
    END LOOP;

    ---------------------------------------------------
    -- Create temporary table to sequence samples
    -- for cart
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_XS (
        request int NOT NULL,
        col int NULL,
        seq int NULL,
        os int PRIMARY KEY GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1)
    );

    ---------------------------------------------------
    -- Copy contents of original request table to
    -- sequence generating table
    ---------------------------------------------------

    INSERT INTO Tmp_XS (request, col)
    SELECT request, col
    FROM Tmp_XR
    ORDER BY Abs(os);

    ---------------------------------------------------
    -- Sequentially number all the samples for each
    -- column so that columns rotate
    ---------------------------------------------------

    -- First, number the sequence field (incrementing by 10)
    -- for each request in each set for each cart column

    _col := 1;

    WHILE _col <= _numCols
    LOOP
        -- The following Update query stores values 10, 20, 30, etc. in the seq column (for a given column)
        -- The Row_Number() function sorts by the identity field "os"

        UPDATE Tmp_XS
        SET seq = CountQ.Seq
        FROM ( SELECT os,
                      Row_Number() OVER (ORDER BY os) * 10 As Seq
               FROM Tmp_XS
               WHERE col = _col) CountQ
        WHERE Tmp_XS.os = CountQ.os

        _col := _col + 1;
    END LOOP;

    -- Next bump the sequence field up by adding the column number
    -- This assumes that there are 9 or fewer columns (since the seq values 10 units apart)

    UPDATE Tmp_XS
    SET seq = seq + col;

    ---------------------------------------------------
    -- Create temporary table to hold the final sequence
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_XF (
        request int NOT NULL,
        col int,
        seq int PRIMARY KEY GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
        blankSeq int null
    );

    ---------------------------------------------------
    -- Populate the final sequence table
    ---------------------------------------------------

    INSERT INTO Tmp_XF (request, col)
    SELECT request, col
    FROM Tmp_XS
    ORDER BY seq;

    ---------------------------------------------------
    -- Check whether all of the entries in Tmp_XF have the same dataset type.
    -- If they do, that type will be reported for the blanks.
    -- If not, but if the type is the same in 75% of the the entries, then the most common dataset type will be used.
    -- Otherwise use Null for the dataset type for blanks.
    ---------------------------------------------------

    _matchCount := 0;
    _requestCountTotal := 0;
    _dsTypeForBlanks := Null;

    SELECT DSType.Dataset_Type,
           COUNT(RR.request_id)
    INTO _dsTypeForBlanks, _matchCount
    FROM t_requested_run RR
         INNER JOIN t_dataset_type_name DSType
           ON RR.request_type_id = DSType.dataset_type_id
         INNER JOIN Tmp_XF
           ON RR.request_id = Tmp_XF.request
    GROUP BY DSType.Dataset_Type
    ORDER BY COUNT(RR.request_id) DESC
    LIMIT 1;

    SELECT COUNT(RR.request_id)
    INTO _requestCountTotal
    FROM t_requested_run RR
         INNER JOIN Tmp_XF
           ON RR.request_id = Tmp_XF.request;

    If _matchCount < _requestCountTotal * 0.75 Then
        _dsTypeForBlanks := Null;
    End If;

    ---------------------------------------------------
    -- Generate sequential numbers for all blanks
    ---------------------------------------------------

    -- Use Row_Number and a self join to populate the blankSeq column

    UPDATE Tmp_XF
    SET blankSeq = CountQ.BlankSeq
    FROM ( SELECT seq,
                  Row_Number() OVER ( ORDER BY Seq ) AS BlankSeq
           FROM Tmp_XF
           WHERE request = 0 ) CountQ
    WHERE Tmp_XF.request = 0 AND
          Tmp_XF.seq = CountQ.Seq

    ---------------------------------------------------
    -- Output final report
    ---------------------------------------------------

    RETURN QUERY
    SELECT
        Tmp_XF.seq AS Sequence,
        (CASE WHEN Tmp_XF.request = 0 THEN format('Blank-%s', Tmp_XF.blankSeq) ELSE RR.request_name END)::citext AS Name,
        Tmp_XF.request AS Request,
        Tmp_XF.col AS Column_Number,
        E.experiment AS Experiment,
        RR.priority AS Priority,
        CASE WHEN Tmp_XF.request = 0 THEN _dsTypeForBlanks ELSE DSType.Dataset_Type END AS Type,
        RR.batch_id AS Batch,
        RR.block As Block,
        RR.run_order AS Run_Order,
        EUT.eus_usage_type AS EMSL_Usage_Type,
        RR.eus_proposal_id AS EMSL_Proposal_ID,
        public.get_requested_run_eus_users_list(RR.request_id, 'I')::citext AS EMSL_Users_List
    FROM t_experiments E
         INNER JOIN t_requested_run RR
           ON E.exp_id = RR.exp_id
         INNER JOIN t_eus_usage_type EUT
           ON RR.eus_usage_type_id = EUT.eus_usage_type_id
         INNER JOIN t_dataset_type_name DSType
           ON RR.request_type_id = DSType.dataset_type_id
         RIGHT OUTER JOIN Tmp_XF
           ON RR.request_id = Tmp_XF.request
    ORDER BY Tmp_XF.seq

    DROP TABLE Tmp_XR;
    DROP TABLE Tmp_XS;
    DROP TABLE Tmp_XF;
END
$$;

COMMENT ON PROCEDURE public.generate_lc_cart_loading_list IS 'GenerateLCCartLoadingList';
