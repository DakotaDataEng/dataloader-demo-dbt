-- The capital invoices only: the invoices coded to a capital cost code, with snake case names.
select
    i."ApInvoiceId" as ap_invoice_id,
    i."VendorId" as vendor_id,
    i."WellId" as well_id,
    i."LeaseId" as lease_id,
    i."AfeId" as afe_id,
    i."CostCode" as cost_code,
    i."InvoiceDate" as invoice_date,
    i."Amount" as amount,
    i."ModifiedDate" as modified_at
from {{ source('og_raw', 'ap_invoice') }} as i
join {{ source('og_raw', 'cost_code') }} as c
    on c."CostCode" = i."CostCode"
where c."Category" = 'Capital'
