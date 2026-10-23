-- The joint interest bills with snake case names.
select
    "JibBillingId" as jib_billing_id,
    cast("BillingMonth" as date) as billing_month,
    "BillingDate" as billing_date,
    "WellId" as well_id,
    "LeaseId" as lease_id,
    "PartnerId" as partner_id,
    "WorkingInterest" as working_interest,
    "GrossCost" as gross_cost,
    "BilledAmount" as billed_amount,
    "Status" as status,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'jib_billing') }}
