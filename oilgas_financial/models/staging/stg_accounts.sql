-- The chart of accounts with snake case names. The raw copy keeps the source's column names, so they are quoted.
select
    "AccountId" as account_id,
    "AccountNumber" as account_number,
    "AccountName" as account_name,
    "AccountType" as account_type,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'account') }}
