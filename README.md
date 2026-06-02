# Report Name:      Active Accounts with Current Services, Lot Address, Area, and Filters
<b>Database:</b>         Springbrook0
<b>Created By:</b>       Teo Espero
<b>Department:</b>       Marina Coast Water District - IT

<b>Purpose:</b>
<p>This query returns utility billing accounts that were active as of a selected date,
     including accounts with acct_status = Delete when their final_date is on or after
     the selected As Of Date.</p>
     
<pre>
     The report includes current service rates, service categories, service address from
     the Lot table, billing area, and lot attributes.
</pre>

<b>Important Notes:</b>
<ol>
  <li>This query does NOT use [dbo].[Customers] because that object is a view and currently
        has a binding error related to charge_phone.</li>
  <li>Service address is pulled from [dbo].[lot].</li>
  <li>Only current service rates are included:
  <ul>
    <li>rate_final_date IS NULL</li>
  </ul>
  <li>Service rates CS, SC, and WC are excluded.</li>
  <li>ServiceZip only returns the first 5 characters.</li>
  <li>Filters support comma-separated values.</li>
  <li>Wildcard filters support SQL wildcard % and user-friendly wildcard *.</li>
  <li>Final output fields are ordered for reporting.</li>
  <li>NULL values are shown as blanks in the final output.</li>
  <li>Active As Of Date logic:
    <ul>
      <li>Include Active accounts if they were connected on or before @AsOfDate
              and final_date is NULL or final_date >= @AsOfDate.</li>
      <li>Include Delete/Deleted accounts if final_date >= @AsOfDate.</li>
    </ul>
    </li>
</ol>

<pre>Service Code Rules:
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
     SubType         = specific, multiple, or wildcard</pre>


 Revision History:

 <table>
  <thead>
    <tr>
      <th>Date</th>
      <th>Author</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Initial version using ub_master, ub_service_rate, ub_service, and Customers.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Removed dependency on dbo.Customers due to charge_phone binding error.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Updated service address to come from dbo.lot.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Added Lot fields: tax_lot, boundary, ST category, subdivision, unit type, sub type, and irrigation.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Added service code classifications for Water, Sewer, Recycled Water, Backflow, Fire, and District Use.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Added billing cycle area logic: 1-4 = Marina, 5-10 = Ord, 11 = MCWD.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Updated service rate filter to only include records where rate_final_date IS NULL.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Excluded CS, SC, and WC service rates.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Formatted DateConnected and FinalDate as MM/DD/YYYY.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Removed Parcel, mailing address fields, and lot contact fields from final output.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Added filter variables for account number, billing cycle, area, service address, boundary, ST category, subdivision, unit type, and sub type.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Reordered final output fields and converted NULL values to blanks.</td>
    </tr>
    <tr>
      <td>06/01/2026</td>
      <td>Teo Espero</td>
      <td>Added Active As Of Date logic. Includes Active accounts and Delete/Deleted accounts when final_date is on or after the selected As Of Date.</td>
    </tr>
  </tbody>
</table>
    
