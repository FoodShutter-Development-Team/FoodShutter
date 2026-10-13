# Course background and engineering process

[Documentation index](README.md) · [Evaluation evidence](evaluation.md)

FoodShutter is a software project management course assignment combining mobile development, model experiments, backend services and a web companion with requirements and management exercises. These documents draw on the final presentation, earlier scope materials, later schedule/risk/configuration exercises and executable source.

## Scope and team

The intended interaction is meal capture, recognition, nutrient breakdown and advice based on personal context. Initial scope also proposes exports, offline synchronization and a schema package. Current implementation status is listed in [architecture](architecture.md#capability-status).

The course excludes medical diagnosis/treatment, Android, social/community functionality and commercial nutrition datasets.

The final presentation's contribution table supplies these public credits. Student IDs and contribution percentages are omitted.

| Member | Reported responsibility |
| --- | --- |
| Liu Xiangyu | iOS, AI backend pipeline, model fine-tuning |
| Xie Tingyang | Testing, documentation/presentation, deployment |
| Liu Simiao | Presentation and illustration design |
| Zhou Yunhui | Documentation |
| Li Peichen | Web frontend, data synchronization |
| Han Chengxu | Backend and web integration support |

Earlier W⁵HH material describes solo development, while later plans and the final table describe six members. Public credits use the final table. Intermediate task-owner assignments do not replace those reported roles or determine Git authorship.

## Management work

| Course artifact | Purpose |
| --- | --- |
| Vision & Scope and W⁵HH | Define user needs, system boundary and acceptance goals |
| LOC, function points and object metrics | Explore size and effort assumptions |
| COCOMO, object points and make/buy analysis | Compare effort models and model/service reuse |
| Scrum and Leangoo materials | Organize stories, sprint goals, reviews and retrospectives |
| Schedule network and EVM | Identify analysis integration dependencies and assess a planning checkpoint |
| RMMM and risk information sheets | Track model instability, duplicate detection, interface mismatch and scope growth |
| Configuration control | Describe change requests, decisions, engineering changes and configuration items |
| FTR | Record inter-group review and follow-up revisions |
| Reliability, safety and CMM/CMMI | Analyze failure scenarios and discuss process discipline |

The final deck reports 12 review suggestions, including three critical revisions, and their follow-up acceptance. This is course review evidence rather than an independent production/security audit.

## Interpretation of figures

The estimation exercises assume six members, four months, 24 person-months, 8,224 production LOC, 374.22 adjusted function points and $28,800 modeled labor cost. These are estimation inputs rather than audited code size or actual spending.

The week-eight EVM exercise uses PV 15.50, EV 14.35 and AC 16.00 person-months, yielding CPI approximately 0.90 and SPI approximately 0.93. These explain the course's schedule analysis rather than proving measured delivery history.

The supporting reliability material explicitly uses simulated data: 100 runs, four failures and 1.5 hours of repair over 48 hours. Its 96.00% reliability and 96.97% availability are teaching calculations. “CMM Level 3: Defined” is an educational self-assessment, with no formal appraisal or certification established.

Course `v0.x`/`v1.0.0` milestones and `PR-01`/`PR-02`/`PR-03` placeholders do not establish actual tags, releases or pull requests. This documentation instead identifies real source baseline `3a7bf20` and preserves the repository's existing history.

## Source register

| Supplied material | Use |
| --- | --- |
| Final PPT, slide 2 | Team roles |
| Final PPT, slides 6–10 | Vision, scope and early technical plan |
| Final PPT, slides 12–46 | Estimation, schedule, risk and process exercises |
| Final PPT, slides 48–49 | Inter-group review and follow-up |
| Final PPT, slide 52 | iOS recording |
| Final PPT, slides 55–63 | System, pipeline, evaluation and model experiments |
| Final PPT, slides 65–73 | Web and database design, web recording |
| Final PPT, slides 75–77 | Model-serving design |
| Final PPT, slides 79–82 | Nutrition database design |
| `task1_vision_scope_final.tex` | Original scope and exclusions |
| Completed schedule/risk/SCM Markdown | Planning assumptions and simulated/placeholder labels |
| Leangoo backlog and retrospective materials | Sprint process context |
| Source baseline `3a7bf20` | Runtime configuration, behavior and tests |

The final PPT is `FoodShutter_finalversion.pptx`. Original teaching files remain in the supplied course folder. Source filenames and slide numbers allow tracing without publishing private local paths or the entire teaching package.
