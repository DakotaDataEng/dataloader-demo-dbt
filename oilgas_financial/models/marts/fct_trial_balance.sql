-- The trial balance: debits, credits and net per ledger account per posting month. The net of all accounts is zero.
select
    md5(account_number || '|' || cast(posting_month as text)) as balance_key,
    account_number,
    account_name,
    account_type,
    posting_month,
    count(*) as line_count,
    sum(debit) as debit,
    sum(credit) as credit,
    sum(net_amount) as net_amount
from {{ ref('int_gl_lines') }}
group by account_number, account_name, account_type, posting_month
