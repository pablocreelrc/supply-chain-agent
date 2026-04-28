# Supply Chain Agent — Skill Catalog

## How this agent is organized

Two layers operate in parallel:

1. **Slash command (`/ai-agents-ops`)** — activates the VP of Operations persona and points the agent at `CLAUDE.md` and `references/tools.md`.
2. **Plugin skills** — the skills under `skills/` are matched automatically by Claude Code's skill matcher based on their frontmatter `description:` triggers. Loaded via `.claude-plugin/marketplace.json`.

The skills live in two git submodules — **Supply-Chain-Pro** (14 skills, supply chain–specific) and **Business-Analytics-Pro** (15 skills, general quantitative analytics). Each submodule maintains its own canonical `CATALOG.md`; what follows is a flattened index for convenience.

> **Architecture note:** registering submodule skills with the agent's plugin manifest (`.claude-plugin/marketplace.json`) is staged work. The current manifest is empty; skills are still discoverable via the submodule structure, and the consolidated registration is being built incrementally.

## Supply-Chain-Pro skills (14)

| # | Skill | Category | Trigger phrases |
|---|-------|----------|-----------------|
| 1 | [newsvendor-model](skills/Supply-Chain-Pro/foundations/newsvendor-model/SKILL.md) | Foundations | newsvendor, critical ratio, overage, underage, capacity sizing, service level, fill rate, EVPI |
| 2 | [eoq-cycle-inventory](skills/Supply-Chain-Pro/foundations/eoq-cycle-inventory/SKILL.md) | Foundations | EOQ, economic order quantity, cycle stock, order cost, holding cost, inventory turns |
| 3 | [safety-stock-policy](skills/Supply-Chain-Pro/foundations/safety-stock-policy/SKILL.md) | Foundations | safety stock, reorder point, service level, lead time, demand uncertainty, risk pooling |
| 4 | [linear-programming-optimization](skills/Supply-Chain-Pro/analytics/linear-programming-optimization/SKILL.md) | Analytics | LP, linear programming, optimization, Solver, shadow price, constraints, allocation |
| 5 | [flexibility-demand-pooling](skills/Supply-Chain-Pro/analytics/flexibility-demand-pooling/SKILL.md) | Analytics | flexibility, demand pooling, chaining, correlation, dedicated capacity, mix flexibility |
| 6 | [supply-chain-contracting](skills/Supply-Chain-Pro/analytics/supply-chain-contracting/SKILL.md) | Analytics | revenue sharing, buyback, double marginalization, coordination, contracts, VMI |
| 7 | [aggregate-planning](skills/Supply-Chain-Pro/analytics/aggregate-planning/SKILL.md) | Analytics | aggregate planning, chase, level, seasonal demand, workforce, overtime, S&OP |
| 8 | [demand-forecasting](skills/Supply-Chain-Pro/analytics/demand-forecasting/SKILL.md) | Analytics | forecasting, exponential smoothing, moving average, Holt, Winters, MAD, MAPE |
| 9 | [network-design](skills/Supply-Chain-Pro/analytics/network-design/SKILL.md) | Analytics | facility location, gravity model, distribution network, centralization, decentralization |
| 10 | [competitive-cost-analysis](skills/Supply-Chain-Pro/advanced/competitive-cost-analysis/SKILL.md) | Advanced | cost benchmarking, value chain, unit economics, competitive advantage |
| 11 | [sustainability-operations](skills/Supply-Chain-Pro/advanced/sustainability-operations/SKILL.md) | Advanced | sustainability, triple bottom line, closed-loop, reverse logistics, carbon pricing, ESG |
| 12 | [end-to-end-capacity-planning](skills/Supply-Chain-Pro/workflows/end-to-end-capacity-planning/SKILL.md) | Workflow | demand-forecasting → newsvendor-model → flexibility-demand-pooling → aggregate-planning |
| 13 | [inventory-system-design](skills/Supply-Chain-Pro/workflows/inventory-system-design/SKILL.md) | Workflow | eoq-cycle-inventory → safety-stock-policy → network-design |
| 14 | [skill-authoring-workflow](skills/Supply-Chain-Pro/infrastructure/skill-authoring-workflow/SKILL.md) | Meta | skill template, quality checklist, authoring guide |

## Business-Analytics-Pro skills (15)

| # | Skill | Category | Trigger phrases |
|---|-------|----------|-----------------|
| 1 | [spreadsheet-modeling](skills/Business-Analytics-Pro/foundations/spreadsheet-modeling/SKILL.md) | Foundations | spreadsheet, breakeven, npv, irr, sensitivity, data-tables |
| 2 | [probability-distributions](skills/Business-Analytics-Pro/probability/probability-distributions/SKILL.md) | Probability | probability, normal, binomial, poisson, exponential, distributions |
| 3 | [decision-analysis](skills/Business-Analytics-Pro/probability/decision-analysis/SKILL.md) | Probability | decision-tree, emv, evpi, bayes, real-options, voi |
| 4 | [monte-carlo-simulation](skills/Business-Analytics-Pro/simulation/monte-carlo-simulation/SKILL.md) | Simulation | monte-carlo, simulation, risk, tornado, flaw-of-averages |
| 5 | [simulation-models](skills/Business-Analytics-Pro/simulation/simulation-models/SKILL.md) | Simulation | correlation, bidding, warranty, cash-balance, cholesky |
| 6 | [intro-to-optimization](skills/Business-Analytics-Pro/optimization/intro-to-optimization/SKILL.md) | Optimization | optimization, linear-programming, solver, shadow-price, sensitivity |
| 7 | [optimization-models](skills/Business-Analytics-Pro/optimization/optimization-models/SKILL.md) | Optimization | integer-programming, transportation, portfolio, markowitz, scheduling |
| 8 | [time-series-forecasting](skills/Business-Analytics-Pro/forecasting/time-series-forecasting/SKILL.md) | Forecasting | time-series, forecasting, exponential-smoothing, winters, mape |
| 9 | [classification](skills/Business-Analytics-Pro/data-mining/classification/SKILL.md) | Data Mining | classification, logistic-regression, naive-bayes, roc, auc |
| 10 | [clustering-market-basket](skills/Business-Analytics-Pro/data-mining/clustering-market-basket/SKILL.md) | Data Mining | clustering, k-means, association-rules, apriori, lift |
| 11 | [investment-analysis](skills/Business-Analytics-Pro/workflows/investment-analysis/SKILL.md) | Workflow | spreadsheet-modeling → monte-carlo-simulation → decision-analysis → optimization-models |
| 12 | [project-valuation](skills/Business-Analytics-Pro/workflows/project-valuation/SKILL.md) | Workflow | spreadsheet-modeling → probability-distributions → monte-carlo-simulation → decision-analysis |
| 13 | [risk-assessment-pipeline](skills/Business-Analytics-Pro/workflows/risk-assessment-pipeline/SKILL.md) | Workflow | probability-distributions → simulation-models → monte-carlo-simulation → decision-analysis |
| 14 | [demand-forecasting-pipeline](skills/Business-Analytics-Pro/workflows/demand-forecasting-pipeline/SKILL.md) | Workflow | time-series-forecasting → monte-carlo-simulation → optimization-models |
| 15 | [skill-authoring-workflow](skills/Business-Analytics-Pro/infrastructure/skill-authoring-workflow/SKILL.md) | Meta | meta, authoring, template |

## Workflows (chained pipelines)

The `workflows/` directory at the agent root is reserved for cross-skill pipelines that span both submodules (e.g., chaining a Supply-Chain-Pro `demand-forecasting` skill with a Business-Analytics-Pro `monte-carlo-simulation`). Populate as multi-step deliverables emerge.

| Workflow | Skills chained | Trigger | File |
|----------|---------------|---------|------|
| *(none yet — populate as cross-submodule workflows are authored)* | | | |
