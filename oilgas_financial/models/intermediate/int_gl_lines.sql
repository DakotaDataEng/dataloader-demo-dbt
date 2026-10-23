-- Every ledger line with its account and posting month.
select
    g.gl_entry_id,
    g.journal_id,
    g.posting_date,
    cast(date_trunc('month', g.posting_date) as date) as posting_month,
    g.account_id,
    a.account_number,
    a.account_name,
    a.account_type,
    g.well_id,
    g.lease_id,
    g.cost_code,
    g.debit,
    g.credit,
    g.debit - g.credit as net_amount,
    g.source_type,
    g.source_id
from {{ ref('stg_gl_entries') }} as g
join {{ ref('stg_accounts') }} as a
    on a.account_id = g.account_id
