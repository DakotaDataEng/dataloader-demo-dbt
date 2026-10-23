-- The general ledger lines with snake case names.
select
    "GlEntryId" as gl_entry_id,
    "JournalId" as journal_id,
    "PostingDate" as posting_date,
    "AccountId" as account_id,
    "WellId" as well_id,
    "LeaseId" as lease_id,
    "CostCode" as cost_code,
    "Debit" as debit,
    "Credit" as credit,
    "SourceType" as source_type,
    "SourceId" as source_id,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'gl_entry') }}
