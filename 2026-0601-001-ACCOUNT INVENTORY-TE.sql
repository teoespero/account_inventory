/**********************************************************************************************
 Report Name:      Active Accounts with Current Services, Lot Address, Area, and Filters
 Database:         Springbrook0
 Created By:       Teo Espero
 Department:       Marina Coast Water District - IT

 Purpose:
     This query returns utility billing accounts that were active as of a selected date,
     including accounts with acct_status = Delete when their final_date is on or after
     the selected As Of Date.

     The report includes current service rates, service categories, service address from
     the Lot table, billing area, and lot attributes.

 Important Notes:
     1. This query does NOT use [dbo].[Customers] because that object is a view and currently
        has a binding error related to charge_phone.
     2. Service address is pulled from [dbo].[lot].
     3. Only current service rates are included:
            rate_final_date IS NULL
     4. Service rates CS, SC, and WC are excluded.
     5. ServiceZip only returns the first 5 characters.
     6. Filters support comma-separated values.
     7. Wildcard filters support SQL wildcard % and user-friendly wildcard *.
     8. Final output fields are ordered for reporting.
     9. NULL values are shown as blanks in the final output.
    10. Active As Of Date logic:
            - Include Active accounts if they were connected on or before @AsOfDate
              and final_date is NULL or final_date >= @AsOfDate.
            - Include Delete/Deleted accounts if final_date >= @AsOfDate.

 Service Code Rules:
     W%  = Water
     S%  = Sewer
     BF% = Backflow
     OF% = Backflow
     F%  = Fire
     RW% = Recycled Water
     OM% = District Use

 Billing Cycle / Area Rules:
     Billing Cycle 1-4  = Marina
     Billing Cycle 5-10 = Ord
     Billing Cycle 11   = MCWD

 Lot Field Mapping:
     misc_1  = Boundary
     misc_2  = ST Category
     misc_5  = Subdivision
     misc_14 = Unit Type
     misc_15 = Sub Type
     misc_16 = Irrigation

 Filter Fields:
     AccountNumber   = specific, multiple, or wildcard
     billing_cycle   = specific or multiple
     Area            = specific, multiple, or wildcard
     ServiceAddress  = specific, multiple, or wildcard
     Boundary        = specific, multiple, or wildcard
     STCategory      = specific, multiple, or wildcard
     Subdivision     = specific, multiple, or wildcard
     UnitType        = specific, multiple, or wildcard
     SubType         = specific, multiple, or wildcard

 Revision History:
     +------------+-------------+---------------------------------------------------------------+
     | Date       | Author      | Description                                                   |
     +------------+-------------+---------------------------------------------------------------+
     | 06/01/2026 | Teo Espero  | Initial version using ub_master, ub_service_rate, ub_service, |
     |            |             | and Customers.                                                |
     | 06/01/2026 | Teo Espero  | Removed dependency on dbo.Customers due to charge_phone       |
     |            |             | binding error.                                                |
     | 06/01/2026 | Teo Espero  | Updated service address to come from dbo.lot.                 |
     | 06/01/2026 | Teo Espero  | Added Lot fields: tax_lot, boundary, ST category,             |
     |            |             | subdivision, unit type, sub type, and irrigation.             |
     | 06/01/2026 | Teo Espero  | Added service code classifications for Water, Sewer,          |
     |            |             | Recycled Water, Backflow, Fire, and District Use.             |
     | 06/01/2026 | Teo Espero  | Added billing cycle area logic: 1-4 = Marina,                 |
     |            |             | 5-10 = Ord, 11 = MCWD.                                        |
     | 06/01/2026 | Teo Espero  | Updated service rate filter to only include records where     |
     |            |             | rate_final_date IS NULL.                                      |
     | 06/01/2026 | Teo Espero  | Excluded CS, SC, and WC service rates.                        |
     | 06/01/2026 | Teo Espero  | Formatted DateConnected and FinalDate as MM/DD/YYYY.          |
     | 06/01/2026 | Teo Espero  | Removed Parcel, mailing address fields, and lot contact       |
     |            |             | fields from final output.                                     |
     | 06/01/2026 | Teo Espero  | Added filter variables for account number, billing cycle,     |
     |            |             | area, service address, boundary, ST category, subdivision,    |
     |            |             | unit type, and sub type.                                      |
     | 06/01/2026 | Teo Espero  | Reordered final output fields and converted NULL values       |
     |            |             | to blanks.                                                    |
     | 06/01/2026 | Teo Espero  | Added Active As Of Date logic. Includes Active accounts and   |
     |            |             | Delete/Deleted accounts when final_date is on or after the    |
     |            |             | selected As Of Date.                                          |
     +------------+-------------+---------------------------------------------------------------+
**********************************************************************************************/

USE [Springbrook0];
GO

/**********************************************************************************************
 As Of Date

 Change this date to run the report as of a specific date.

 Example:
     DECLARE @AsOfDate date = '2026-06-01';
**********************************************************************************************/

DECLARE @AsOfDate date = GETDATE();

/**********************************************************************************************
 Filter Variables

 Leave as NULL to return all records.

 Examples:
     Specific:
         DECLARE @AccountNumberFilter varchar(max) = '022971-000';

     Multiple:
         DECLARE @AccountNumberFilter varchar(max) = '022971-000,015383-504';

     Wildcard:
         DECLARE @AccountNumberFilter varchar(max) = '022971%';
         DECLARE @ServiceAddressFilter varchar(max) = '%IMJIN%';

     User-friendly wildcard also works:
         DECLARE @ServiceAddressFilter varchar(max) = '*IMJIN*';
**********************************************************************************************/

DECLARE @AccountNumberFilter  varchar(max) = NULL;
DECLARE @BillingCycleFilter   varchar(max) = NULL;
DECLARE @AreaFilter           varchar(max) = NULL;
DECLARE @ServiceAddressFilter varchar(max) = NULL;
DECLARE @BoundaryFilter       varchar(max) = NULL;
DECLARE @STCategoryFilter     varchar(max) = NULL;
DECLARE @SubdivisionFilter    varchar(max) = NULL;
DECLARE @UnitTypeFilter       varchar(max) = NULL;
DECLARE @SubTypeFilter        varchar(max) = NULL;

WITH AccountBase AS
(
    SELECT
        m.ub_master_id,
        m.cust_no,
        m.cust_sequence,

        AccountNumber =
            RIGHT('000000' + CAST(m.cust_no AS varchar(20)), 6)
            + '-'
            + RIGHT('000' + CAST(m.cust_sequence AS varchar(20)), 3),

        m.lot_no,
        m.billing_cycle,
        BillingCycleSort = TRY_CONVERT(int, m.billing_cycle),

        Area =
            CASE
                WHEN TRY_CONVERT(int, m.billing_cycle) BETWEEN 1 AND 4 THEN 'Marina'
                WHEN TRY_CONVERT(int, m.billing_cycle) BETWEEN 5 AND 10 THEN 'Ord'
                WHEN TRY_CONVERT(int, m.billing_cycle) = 11 THEN 'MCWD'
                WHEN m.billing_cycle IS NULL THEN ''
                ELSE 'Review'
            END,

        m.acct_status,
        m.connect_date,
        m.final_date

    FROM [Springbrook0].[dbo].[ub_master] m
    WHERE
        -- Account must have been connected on or before the As Of Date.
        (m.connect_date IS NULL OR m.connect_date <= @AsOfDate)

        AND
        (
            -- Active accounts as of the selected date.
            (
                UPPER(LTRIM(RTRIM(ISNULL(m.acct_status, '')))) IN ('A', 'ACTIVE')
                AND (m.final_date IS NULL OR m.final_date >= @AsOfDate)
            )

            OR

            -- Delete/Deleted accounts that were still active as of the selected date.
            (
                UPPER(LTRIM(RTRIM(ISNULL(m.acct_status, '')))) IN ('D', 'DELETE', 'DELETED')
                AND m.final_date >= @AsOfDate
            )
        )
),

LotBase AS
(
    SELECT
        l.lot_no,
        l.tax_lot,

        ServiceAddress =
            LTRIM(RTRIM(CONCAT(
                ISNULL(CAST(l.street_number AS varchar(50)), ''),
                CASE 
                    WHEN ISNULL(l.street_directional, '') <> '' 
                    THEN ' ' + l.street_directional 
                    ELSE '' 
                END,
                CASE 
                    WHEN ISNULL(l.street_name, '') <> '' 
                    THEN ' ' + l.street_name 
                    ELSE '' 
                END,
                CASE 
                    WHEN ISNULL(l.addr_2, '') <> '' 
                    THEN ' ' + l.addr_2 
                    ELSE '' 
                END
            ))),

        ServiceCity  = l.city,
        ServiceState = l.state,
        ServiceZip   = LEFT(LTRIM(RTRIM(CAST(l.zip AS varchar(20)))), 5),

        Boundary    = l.misc_1,
        STCategory  = l.misc_2,
        Subdivision = l.misc_5,
        UnitType    = l.misc_14,
        SubType     = l.misc_15,
        Irrigation  = l.misc_16

    FROM [Springbrook0].[dbo].[lot] l
),

ActiveServiceRates AS
(
    SELECT
        sr.cust_no,
        sr.cust_sequence,
        sr.service_number,
        service_code = UPPER(LTRIM(RTRIM(sr.service_code))),
        sr.description AS ServiceRateDescription,
        sr.rate_connect_date,
        sr.rate_final_date,
        sr.active

    FROM [Springbrook0].[dbo].[ub_service_rate] sr
    WHERE
        sr.rate_final_date IS NULL
        AND UPPER(LTRIM(RTRIM(sr.service_code))) NOT IN ('CS', 'SC', 'WC')
),

ServiceClassified AS
(
    SELECT DISTINCT
        sr.cust_no,
        sr.cust_sequence,
        sr.service_number,
        sr.service_code,

        ServiceDescription =
            COALESCE(s.description, sr.ServiceRateDescription),

        ServiceCategory =
            CASE
                WHEN sr.service_code LIKE 'RW%' THEN 'Recycled Water'
                WHEN sr.service_code LIKE 'BF%' THEN 'Backflow'
                WHEN sr.service_code LIKE 'OF%' THEN 'Backflow'
                WHEN sr.service_code LIKE 'OM%' THEN 'District Use'
                WHEN sr.service_code LIKE 'F%'  THEN 'Fire'
                WHEN sr.service_code LIKE 'S%'  THEN 'Sewer'
                WHEN sr.service_code LIKE 'W%'  THEN 'Water'
                ELSE 'Other'
            END

    FROM ActiveServiceRates sr
    LEFT JOIN [Springbrook0].[dbo].[ub_service] s
        ON sr.service_number = s.service_number
       AND sr.service_code = UPPER(LTRIM(RTRIM(s.service_code)))
),

ServiceSummary AS
(
    SELECT
        cust_no,
        cust_sequence,

        HasWater =
            CASE 
                WHEN MAX(CASE WHEN ServiceCategory = 'Water' THEN 1 ELSE 0 END) = 1
                THEN 'Yes' ELSE 'No'
            END,

        HasSewer =
            CASE 
                WHEN MAX(CASE WHEN ServiceCategory = 'Sewer' THEN 1 ELSE 0 END) = 1
                THEN 'Yes' ELSE 'No'
            END,

        HasRecycledWater =
            CASE 
                WHEN MAX(CASE WHEN ServiceCategory = 'Recycled Water' THEN 1 ELSE 0 END) = 1
                THEN 'Yes' ELSE 'No'
            END,

        HasBackflow =
            CASE 
                WHEN MAX(CASE WHEN ServiceCategory = 'Backflow' THEN 1 ELSE 0 END) = 1
                THEN 'Yes' ELSE 'No'
            END,

        HasFire =
            CASE 
                WHEN MAX(CASE WHEN ServiceCategory = 'Fire' THEN 1 ELSE 0 END) = 1
                THEN 'Yes' ELSE 'No'
            END,

        HasDistrictUse =
            CASE 
                WHEN MAX(CASE WHEN ServiceCategory = 'District Use' THEN 1 ELSE 0 END) = 1
                THEN 'Yes' ELSE 'No'
            END,

        ServiceCodes =
            STRING_AGG(CAST(service_code AS varchar(max)), ', '),

        Services =
            STRING_AGG(
                CAST(
                    ServiceCategory
                    + ' - '
                    + service_code
                    + ' - '
                    + ISNULL(ServiceDescription, '')
                    AS varchar(max)
                ),
                '; '
            )

    FROM ServiceClassified
    GROUP BY
        cust_no,
        cust_sequence
),

FinalReport AS
(
    SELECT
        Area             = ISNULL(a.Area, ''),
        STCategory       = ISNULL(l.STCategory, ''),
        Boundary         = ISNULL(l.Boundary, ''),
        Subdivision      = ISNULL(l.Subdivision, ''),
        billing_cycle    = ISNULL(CAST(a.billing_cycle AS varchar(20)), ''),
        BillingCycleSort = a.BillingCycleSort,

        AccountNumber    = ISNULL(a.AccountNumber, ''),
        lot_no           = ISNULL(CAST(a.lot_no AS varchar(50)), ''),
        tax_lot          = ISNULL(CAST(l.tax_lot AS varchar(50)), ''),

        ServiceAddress   = ISNULL(l.ServiceAddress, ''),
        ServiceCity      = ISNULL(l.ServiceCity, ''),
        ServiceState     = ISNULL(l.ServiceState, ''),
        ServiceZip       = ISNULL(l.ServiceZip, ''),

        UnitType         = ISNULL(l.UnitType, ''),
        SubType          = ISNULL(l.SubType, ''),
        Irrigation       = ISNULL(l.Irrigation, ''),

        HasWater         = ISNULL(s.HasWater, 'No'),
        HasSewer         = ISNULL(s.HasSewer, 'No'),
        HasRecycledWater = ISNULL(s.HasRecycledWater, 'No'),
        HasBackflow      = ISNULL(s.HasBackflow, 'No'),
        HasFire          = ISNULL(s.HasFire, 'No'),
        HasDistrictUse   = ISNULL(s.HasDistrictUse, 'No'),

        ServiceCodes     = ISNULL(s.ServiceCodes, ''),
        Services         = ISNULL(s.Services, ''),

        AccountStatus    = ISNULL(a.acct_status, ''),
        DateConnected    = ISNULL(CONVERT(varchar(10), a.connect_date, 101), ''),
        FinalDate        = ISNULL(CONVERT(varchar(10), a.final_date, 101), '')

    FROM AccountBase a
    LEFT JOIN LotBase l
        ON LTRIM(RTRIM(CAST(a.lot_no AS varchar(50)))) =
           LTRIM(RTRIM(CAST(l.lot_no AS varchar(50))))
    LEFT JOIN ServiceSummary s
        ON s.cust_no = a.cust_no
       AND s.cust_sequence = a.cust_sequence
)

SELECT
    Area,
    STCategory,
    Boundary,
    Subdivision,
    billing_cycle,
    AccountNumber,
    lot_no,
    tax_lot,
    ServiceAddress,
    ServiceCity,
    ServiceState,
    ServiceZip,
    UnitType,
    SubType,
    Irrigation,
    HasWater,
    HasSewer,
    HasRecycledWater,
    HasBackflow,
    HasFire,
    HasDistrictUse,
    ServiceCodes,
    Services,
    AccountStatus,
    DateConnected,
    FinalDate

FROM FinalReport fr

WHERE
    (
        @AccountNumberFilter IS NULL
        OR LTRIM(RTRIM(@AccountNumberFilter)) = ''
        OR EXISTS
        (
            SELECT 1
            FROM STRING_SPLIT(@AccountNumberFilter, ',') f
            WHERE fr.AccountNumber LIKE REPLACE(LTRIM(RTRIM(f.value)), '*', '%')
        )
    )

    AND
    (
        @BillingCycleFilter IS NULL
        OR LTRIM(RTRIM(@BillingCycleFilter)) = ''
        OR EXISTS
        (
            SELECT 1
            FROM STRING_SPLIT(@BillingCycleFilter, ',') f
            WHERE TRY_CONVERT(int, fr.billing_cycle) = TRY_CONVERT(int, LTRIM(RTRIM(f.value)))
        )
    )

    AND
    (
        @AreaFilter IS NULL
        OR LTRIM(RTRIM(@AreaFilter)) = ''
        OR EXISTS
        (
            SELECT 1
            FROM STRING_SPLIT(@AreaFilter, ',') f
            WHERE fr.Area LIKE REPLACE(LTRIM(RTRIM(f.value)), '*', '%')
        )
    )

    AND
    (
        @ServiceAddressFilter IS NULL
        OR LTRIM(RTRIM(@ServiceAddressFilter)) = ''
        OR EXISTS
        (
            SELECT 1
            FROM STRING_SPLIT(@ServiceAddressFilter, ',') f
            WHERE fr.ServiceAddress LIKE REPLACE(LTRIM(RTRIM(f.value)), '*', '%')
        )
    )

    AND
    (
        @BoundaryFilter IS NULL
        OR LTRIM(RTRIM(@BoundaryFilter)) = ''
        OR EXISTS
        (
            SELECT 1
            FROM STRING_SPLIT(@BoundaryFilter, ',') f
            WHERE fr.Boundary LIKE REPLACE(LTRIM(RTRIM(f.value)), '*', '%')
        )
    )

    AND
    (
        @STCategoryFilter IS NULL
        OR LTRIM(RTRIM(@STCategoryFilter)) = ''
        OR EXISTS
        (
            SELECT 1
            FROM STRING_SPLIT(@STCategoryFilter, ',') f
            WHERE fr.STCategory LIKE REPLACE(LTRIM(RTRIM(f.value)), '*', '%')
        )
    )

    AND
    (
        @SubdivisionFilter IS NULL
        OR LTRIM(RTRIM(@SubdivisionFilter)) = ''
        OR EXISTS
        (
            SELECT 1
            FROM STRING_SPLIT(@SubdivisionFilter, ',') f
            WHERE fr.Subdivision LIKE REPLACE(LTRIM(RTRIM(f.value)), '*', '%')
        )
    )

    AND
    (
        @UnitTypeFilter IS NULL
        OR LTRIM(RTRIM(@UnitTypeFilter)) = ''
        OR EXISTS
        (
            SELECT 1
            FROM STRING_SPLIT(@UnitTypeFilter, ',') f
            WHERE fr.UnitType LIKE REPLACE(LTRIM(RTRIM(f.value)), '*', '%')
        )
    )

    AND
    (
        @SubTypeFilter IS NULL
        OR LTRIM(RTRIM(@SubTypeFilter)) = ''
        OR EXISTS
        (
            SELECT 1
            FROM STRING_SPLIT(@SubTypeFilter, ',') f
            WHERE fr.SubType LIKE REPLACE(LTRIM(RTRIM(f.value)), '*', '%')
        )
    )

ORDER BY
    fr.Area,
    fr.STCategory,
    fr.Boundary,
    fr.Subdivision,
    fr.BillingCycleSort,
    fr.AccountNumber;