-- The ledger balances: total debits equal total credits, every journal balances, the trial balance nets to zero,
-- credits to accounts payable (2000) equal the AP invoices, and debits to joint interest receivable (1200) equal the JIB bills.
select 'debits and credits differ' as problem
from (select sum(debit) as d, sum(credit) as c from {{ ref('stg_gl_entries') }}) t
where d <> c
union all
select 'trial balance does not net to zero'
from (select sum(net_amount) as n from {{ ref('fct_trial_balance') }}) t
where n <> 0
union all
select 'journal ' || journal_id from {{ ref('int_journals') }} where not is_balanced
union all
select 'accounts payable credits differ from AP invoices'
from (select sum(credit) as c from {{ ref('int_gl_lines') }} where account_number = '2000') g
cross join (select sum("Amount") as a from {{ source('og_raw', 'ap_invoice') }}) i
where g.c <> i.a
union all
select 'joint interest receivable differs from JIB bills'
from (select sum(debit) as d from {{ ref('int_gl_lines') }} where account_number = '1200') g
cross join (select sum(billed_amount) as b from {{ ref('stg_jib_billings') }}) j
where g.d <> j.b
