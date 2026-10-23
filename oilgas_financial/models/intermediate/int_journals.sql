-- One row per journal: the pair of ledger lines an invoice or a joint interest bill posts. A journal balances when its debits equal its credits.
select
    journal_id,
    min(posting_date) as posting_date,
    min(source_type) as source_type,
    min(source_id) as source_id,
    count(*) as line_count,
    sum(debit) as debit,
    sum(credit) as credit,
    sum(debit) = sum(credit) as is_balanced
from {{ ref('int_gl_lines') }}
group by journal_id
