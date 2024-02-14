--
-- Name: generate_lc_cart_loading_list(text, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.generate_lc_cart_loading_list(_lccartname text, _blanksfollowingrequests text DEFAULT ''::text, _columnswithleadingblanks text DEFAULT ''::text) RETURNS TABLE(sequence integer, name public.citext, request integer, column_number integer, experiment public.citext, priority smallint, type public.citext, batch integer, block integer, run_order integer, emsl_usage_type public.citext, emsl_proposal_id public.citext, emsl_users_list public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generate a sample loading list for the given LC cart
**
**      This function is likely unused in 2022, since cart_column (cart column ID) in t_requested_run has only had null values since September 2020,
**      and this function raises a warning and exits if any of the matching requested runs has a null cart column ID value
**
**      Stats by year:
**        SELECT Extract(year from Entered) AS RR_Year,
**               Sum(CASE WHEN NOT Cart_Column IS NULL THEN 1 ELSE 0 END) AS Requests_with_Non_Null_Cart_Col,
**               Sum(CASE WHEN     Cart_Column > 1     THEN 1 ELSE 0 END) AS Requests_with_Cart_Col_Over_One
**        FROM T_Requested_Run
**        GROUP BY RR_Year
**        ORDER BY RR_Year DESC;
**
**      Additionally, all active requested runs in 2024 have cart 'Unknown' or 'No_Cart':
**        SELECT C.cart_name, COUNT(*) as Run_Requests
**        FROM t_requested_run RR
**             INNER JOIN t_lc_cart C
**               ON RR.cart_id = C.cart_id
**        WHERE RR.state_name = 'Active'
**        GROUP BY C.cart_name;
**
**  Arguments:
**    _lcCartName                   LC cart name
**    _blanksFollowingRequests      Comma-separated list of request IDs for which a blank dataset should be added after the request ID
**    _columnsWithLeadingBlanks     Comma-separated list of column IDs for which a leading blank dataset should be added
**
**  Auth:   grk
**  Date:   04/09/2007 (Ticket #424)
**          04/16/2007 grk - Added priority as highest sort attribute
**          06/07/2007 grk - Added EMSL user columns to output (Ticket #488)
**          07/31/2007 mem - Now returning Dataset Type for each request (Ticket #505)
**          08/27/2007 grk - Add ability to start columns with a blank (Ticket #517)
**          09/17/2009 grk - Added check for requests that don't have column assignments
**          02/13/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _columnNumber int;
    _columnCount int;
    _maxSamples int;
    _qLen int;
    _padCnt int;
    _c int;
    _maxEntryID int;
    _matchCount int;
    _requestCountTotal int;
    _dsTypeForBlanks text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _lcCartName               := Trim(Coalesce(_lcCartName, ''));
    _blanksFollowingRequests  := Trim(Coalesce(_blanksFollowingRequests, ''));
    _columnsWithLeadingBlanks := Trim(Coalesce(_columnsWithLeadingBlanks, ''));

    ---------------------------------------------------
    -- Create a temporary table to hold the requested runs assigned to the cart
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_XR (
        request_id int NOT NULL,
        cart_column_id int NULL,
        entry_id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 2)
    );

    ---------------------------------------------------
    -- Populate temporary table with active requested runs assigned to this cart
    ---------------------------------------------------

    INSERT INTO Tmp_XR ( request_id, cart_column_id )
    SELECT RR.request_id,
           RR.cart_column      -- Cart column ID: null for all requested runs since 2020-09-24
    FROM t_requested_run RR
         INNER JOIN t_lc_cart C
           ON RR.cart_id = C.cart_id
    WHERE C.cart_name = _lcCartName::citext AND
          RR.state_name = 'Active'
    ORDER BY RR.priority DESC,
             RR.batch_id,
             RR.run_order,
             RR.request_id;

    ---------------------------------------------------
    -- Verify that all requests have column assignments
    ---------------------------------------------------

    If Exists (SELECT request_id FROM Tmp_XR WHERE cart_column_id IS NULL) Then
        RAISE WARNING 'Some requests do not have column assignments';

        DROP TABLE Tmp_XR;
        RETURN;
    End If;

    ---------------------------------------------------
    -- How many columns need to be used for this cart?
    ---------------------------------------------------

    SELECT COUNT(DISTINCT cart_column_id)
    INTO _columnCount
    FROM Tmp_XR;

    ---------------------------------------------------
    -- Add following blanks to table
    ---------------------------------------------------

    If _blanksFollowingRequests <> '' Then
        INSERT INTO Tmp_XR (request_id, cart_column_id, entry_id)
        OVERRIDING SYSTEM VALUE
        SELECT 0, cart_column_id, entry_id + 1
        FROM Tmp_XR
        WHERE request_id IN (SELECT value FROM public.parse_delimited_integer_list(_blanksFollowingRequests));
    End If;

    ---------------------------------------------------
    -- Add column leading blanks to table
    ---------------------------------------------------

    If _columnsWithLeadingBlanks <> '' Then
        INSERT INTO Tmp_XR (request_id, cart_column_id, entry_id)
        OVERRIDING SYSTEM VALUE
        SELECT 0, value, -value
        FROM public.parse_delimited_integer_list(_columnsWithLeadingBlanks);
    End If;

    ---------------------------------------------------
    -- Pad out ends of column queues with blanks
    ---------------------------------------------------

    -- How many samples in longest column queue?

    SELECT MAX(CountQ.SampleCount)
    INTO _maxSamples
    FROM ( SELECT COUNT(request_id) AS SampleCount
           FROM Tmp_XR
           GROUP BY cart_column_id ) CountQ;

    SELECT MAX(entry_id)
    INTO _maxEntryID
    FROM Tmp_XR;

    FOR _columnNumber IN 1 .. _columnCount
    LOOP
        -- How many samples in column queue?

        SELECT COUNT(request_id)
        INTO _qLen
        FROM Tmp_XR
        WHERE cart_column_id = _columnNumber;

        -- Number of blanks to add

        _padCnt := _maxSamples - _qLen;

        -- Append blanks

        FOR _c IN 1 .. _padCnt
        LOOP
            INSERT INTO Tmp_XR (request_id, cart_column_id, entry_id)
            VALUES (0, _columnNumber, _maxEntryID + 1);

            _maxEntryID := _maxEntryID + 1;
        END LOOP;

    END LOOP;

    ---------------------------------------------------
    -- Create temporary table to sequence samples for cart
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_XS (
        request_id int NOT NULL,
        cart_column_id int NULL,
        seq int NULL,
        entry_id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1)
    );

    ---------------------------------------------------
    -- Copy contents of original request table to sequence generating table
    ---------------------------------------------------

    INSERT INTO Tmp_XS (request_id, cart_column_id)
    SELECT Src.cart_column_id, Src.cart_column_id
    FROM Tmp_XR Src
    ORDER BY Abs(Src.entry_id);

    ---------------------------------------------------
    -- Sequentially number all the samples for each column so that columns rotate
    ---------------------------------------------------

    -- First, number the sequence field (incrementing by 10)
    -- for each request in each set for each cart column

    FOR _columnNumber IN 1 .. _columnCount
    LOOP
        -- The following Update query stores values 10, 20, 30, etc. in the seq column (for a given column)
        -- The Row_Number() function sorts by the identity field "entry_id"

        UPDATE Tmp_XS
        SET seq = CountQ.Seq
        FROM ( SELECT entry_id,
                      Row_Number() OVER (ORDER BY entry_id) * 10 As Seq
               FROM Tmp_XS
               WHERE cart_column_id = _columnNumber) CountQ
        WHERE Tmp_XS.entry_id = CountQ.entry_id;

    END LOOP;

    -- Next bump the sequence field up by adding the column number
    -- This assumes that there are 9 or fewer columns (since the seq values 10 units apart)

    UPDATE Tmp_XS
    SET seq = seq + cart_column_id;

    ---------------------------------------------------
    -- Create temporary table to hold the final sequence
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_XF (
        request_id int NOT NULL,
        cart_column_id int,
        seq int PRIMARY KEY GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
        blankSeq int null
    );

    ---------------------------------------------------
    -- Populate the final sequence table
    ---------------------------------------------------

    INSERT INTO Tmp_XF (request_id, cart_column_id)
    SELECT Src.request_id, Src.cart_column_id
    FROM Tmp_XS Src
    ORDER BY Src.seq;

    ---------------------------------------------------
    -- Check whether all of the entries in Tmp_XF have the same dataset type.
    -- If they do, that type will be reported for the blanks.
    -- If not, but if the type is the same in 75% of the the entries, the most common dataset type will be used.
    -- Otherwise use Null for the dataset type for blanks.
    ---------------------------------------------------

    _matchCount        := 0;
    _requestCountTotal := 0;
    _dsTypeForBlanks   := null;

    SELECT DSType.Dataset_Type,
           COUNT(RR.request_id)
    INTO _dsTypeForBlanks, _matchCount
    FROM t_requested_run RR
         INNER JOIN t_dataset_type_name DSType
           ON RR.request_type_id = DSType.dataset_type_id
         INNER JOIN Tmp_XF
           ON RR.request_id = Tmp_XF.request_id
    GROUP BY DSType.Dataset_Type
    ORDER BY COUNT(RR.request_id) DESC
    LIMIT 1;

    SELECT COUNT(RR.request_id)
    INTO _requestCountTotal
    FROM t_requested_run RR
         INNER JOIN Tmp_XF
           ON RR.request_id = Tmp_XF.request_id;

    If _matchCount < _requestCountTotal * 0.75 Then
        _dsTypeForBlanks := null;
    End If;

    ---------------------------------------------------
    -- Generate sequential numbers for all blanks
    ---------------------------------------------------

    -- Use Row_Number and a self join to populate the blankSeq column

    UPDATE Tmp_XF
    SET blankSeq = CountQ.BlankSeq
    FROM ( SELECT RankSrc.seq,
                  Row_Number() OVER ( ORDER BY RankSrc.Seq ) AS BlankSeq
           FROM Tmp_XF RankSrc
           WHERE RankSrc.request_id = 0 ) CountQ
    WHERE Tmp_XF.request_id = 0 AND
          Tmp_XF.seq = CountQ.Seq;

    ---------------------------------------------------
    -- Output final report
    ---------------------------------------------------

    RETURN QUERY
    SELECT
        Tmp_XF.seq AS Sequence,
        (CASE WHEN Tmp_XF.request_id = 0 THEN format('Blank-%s', Tmp_XF.blankSeq) ELSE RR.request_name END)::citext AS Name,
        Tmp_XF.request_id AS Request,
        Tmp_XF.cart_column_id AS Column_Number,
        E.experiment AS Experiment,
        RR.priority AS Priority,
        CASE WHEN Tmp_XF.request_id = 0 THEN _dsTypeForBlanks::citext ELSE DSType.Dataset_Type END AS Type,
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
           ON RR.request_id = Tmp_XF.request_id
    ORDER BY Tmp_XF.seq;

    DROP TABLE Tmp_XR;
    DROP TABLE Tmp_XS;
    DROP TABLE Tmp_XF;
END
$$;


ALTER FUNCTION public.generate_lc_cart_loading_list(_lccartname text, _blanksfollowingrequests text, _columnswithleadingblanks text) OWNER TO d3l243;

--
-- Name: FUNCTION generate_lc_cart_loading_list(_lccartname text, _blanksfollowingrequests text, _columnswithleadingblanks text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.generate_lc_cart_loading_list(_lccartname text, _blanksfollowingrequests text, _columnswithleadingblanks text) IS 'GenerateLCCartLoadingList';

