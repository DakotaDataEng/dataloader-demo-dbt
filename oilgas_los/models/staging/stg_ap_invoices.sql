-- The vendor invoices with snake case names. The raw copy keeps the source's column names, so they are quoted.
select
    "ApInvoiceId" as ap_invoice_id,
    "InvoiceNumber" as invoice_number,
    "VendorId" as vendor_id,
    "WellId" as well_id,
    "LeaseId" as lease_id,
    "AfeId" as afe_id,
    "CostCode" as cost_code,
    "InvoiceDate" as invoice_date,
    "Amount" as amount,
    "Status" as status,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'ap_invoice') }}
