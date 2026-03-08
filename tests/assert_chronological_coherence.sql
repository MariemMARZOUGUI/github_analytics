select
    pr_number, 
    pr_created_at,
    pr_closed_at
from {{ ref('stg_pull_requests') }}
where pr_closed_at < pr_created_at

union all


select
    issue_id,
    issue_created_at,
    issue_closed_at
from {{ ref('stg_issues') }}
where issue_closed_at < issue_created_at