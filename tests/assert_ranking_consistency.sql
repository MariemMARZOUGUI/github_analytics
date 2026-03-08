select
    repo_id,
    score_global,
    ranking
from {{ ref('scoring_repositories') }}
where ranking = 1
and score_global < (
    select max(score_global)
    from {{ ref('scoring_repositories') }}
)

-- Fails if any two repos share the same ranking
union all

select
    repo_id,
    score_global,
    ranking
from (
    select
        repo_id,
        score_global,
        ranking,
        count(*) over (partition by ranking) as ranking_count
    from {{ ref('scoring_repositories') }}
) 
where ranking_count > 1