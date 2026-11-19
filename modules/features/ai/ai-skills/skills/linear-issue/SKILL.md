---
name: linear-issue
description: Generate an optimized Linear issue title and description. Use when the user asks to create a Linear issue, task description, or says "cria issue", "gera issue", "escreve a issue".
argument-hint: "[brief context of the task]"
---

Generate a Linear issue title and description optimized for the company's AI scoring system.

## Scoring formula
```
score_issue = (complexidade * 0.70) + (impacto * 1.20) + (eficiência * 0.50) + (documentação * 1.00)
score_total = Σ(issues ajustadas) + quantidade^0.70 * 0.70
bônus       = R$500 + ajustes por critério vs referência da trilha
```

Anti-gaming (peso 1.00): penaliza repetição, fragmentação artificial, subtarefas excessivas, variações mecânicas.

---

## Scoring weights (highest first)
- **Impacto** (1.20): quantified metrics, business consequences, scope of affected users
- **Documentação/Handoff** (1.00): clear enough for another person to execute and operate without asking questions
- **Complexidade** (0.70): technical depth, multiple layers affected, architectural decisions
- **Eficiência** (0.50): lean solution, reuse, no over-engineering

---

## Strategic advice (share with user when relevant)

### On quantity vs quality
The quantity boost is **sublinear** (`n^0.70`): doubling issues gives only ~62% more boost.
A few high-scoring issues beat many low-scoring ones. Ideal range: 5–10 well-documented issues per cycle.

### On anti-gaming
- **Group** related small changes into one issue with broader scope — never split artificially
- Each issue must have **distinct scope and outcome** from others
- Avoid mechanical patterns (e.g., "apply same fix to 3 services" = 1 issue, not 3)

### On timing
- Add evidence (screenshots, PR links, config tables) **before the snapshot is taken**
- An issue with missing evidence scores lower on documentação even if the work was excellent

### On efficiency signaling
Explicitly mention in the description:
- What existing components were reused
- What was deliberately NOT built (scope control)
- Why the solution is minimal for the problem

### On complexity signaling
Explicitly list:
- Number of layers affected (code + infra + CI/CD + client = more complex)
- Architectural decisions made and trade-offs considered
- Non-obvious constraints that shaped the solution

### On impact framing
Always quantify the problem being solved:
- Before: "load average de 400", "builds de 8 minutos", "502s em produção"
- After: expected improvement in the same metric
- Scope: how many users/services/requests are affected

---

## Title format
```
<concrete action> para <expected outcome>
```
Types: `feat`, `fix`, `chore`, `ci`, `refactor`
Include the benefit in the title, not just the action.

---

## Description structure

### 1. Problema
- Current state with **quantified metrics** (load average, latency, error %, cost, build time)
- Comparative table if multiple components with different characteristics
- Clear business/user impact

### 2. Impacto Esperado
- Bullet points with concrete, measurable benefits
- Cover: cost, stability, observability, performance

### 3. Solução
- Chosen approach and **why** (architectural decision + trade-offs)
- Subsections per affected layer (code, infra, CI/CD, client)
- Tables for changes per file
- Relevant config/code snippets

### 4. Critérios de Aceite
- `- [ ]` checklist with testable, objective items
- Cover happy path, edge cases and integration with dependencies

### 5. Evidências (preencher após entrega)
- `- [ ]` checklist of what must be documented as proof **before the snapshot**:
  - Before/after metrics screenshots
  - PR links
  - Final config table with real production values
  - Test results (curl, logs, monitoring)
  - Short ADR for key architectural decisions (3 lines minimum)

---

## Language
Write in **Portuguese (pt-BR)** unless the user asks otherwise.
