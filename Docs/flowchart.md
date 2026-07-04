# Vegetable Growth Prediction & Monitoring App — Flowchart

flowchart TD
    A[Start app] --> B[User input form<br/>Vegetable, date, stage, season]
    B --> C[Environmental input<br/>Sunlight, water, soil ratings]
    C --> D{Fields complete?}
    D -->|No| D1[Show input error]
    D1 --> C
    D -->|Yes| E[Map inputs to cell state<br/>Current stage = initial cell value]
    E --> F[Calculate elapsed days<br/>Planting date to current date]
    F --> G[Score each factor 0 to 1<br/>Sunlight, water, soil, season modifier]
    G --> H[Apply CA transition rule<br/>Advance if combined score exceeds threshold]
    H --> I{Threshold met?}
    I -->|No| I1[Stage stays the same]
    I -->|Yes| I2[Advance to next stage<br/>Seedling to fruiting sequence]
    I1 --> J[Predicted growth stage set]
    I2 --> J
    J --> K[Check each factor vs threshold<br/>Sunlight low, water low, soil poor]
    K --> L{Any factor low?}
    L -->|Yes| L1[Flag deficiencies<br/>List each low factor<br/>Status = at risk]
    L -->|No| L2[Mark as healthy<br/>Status = healthy]
    L1 --> M[Match tips to flagged factors<br/>e.g. low sunlight to relocate tip]
    L2 --> M
    M --> N[Compile results screen<br/>Stage, health status, recommendations]
    N --> O[Display to user]
    O --> P[Save run to monitoring log<br/>Timestamp, stage, status, inputs]
    P --> Q[Return to home screen<br/>Wait for next input or view log]`

## Notes for implementation

- **User input form**: vegetable type, planting date, current growth stage, season, sunlight exposure, water availability, soil quality
- **Cellular automata grid**: each cell represents a growth state; transition rules move a cell to the next stage based on weighted environmental factors
- **Growth stages**: Seedling → Young plant → Flowering → Fruiting
- **Health evaluation**: rule-based thresholds per factor (e.g. sunlight below X hours = deficient)
- **Recommendations**: mapped 1:1 to flagged deficient factors
- **Monitoring log**: stores each prediction run with date/time for history tracking in the app
