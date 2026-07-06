flowchart TD
    %% Styling
    classDef page fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef logic fill:#efebe9,stroke:#4e342e,stroke-width:2px;
    classDef data fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px;
    
    %% 1. Onboarding & Entry
    Start([User Opens App]) --> Intro[Introduction Page<br/>Welcome & App Overview]
    Intro --> Home[Home / Landing Page<br/>Show Dashboard & Plant Statistics]
    
    %% 2. Navigation Bar
    Home --> Nav{Bottom Navigation Bar}
    Nav --> |Tab 1| Home
    Nav --> |Tab 2| AddPlantPage[Add Plant Page]
    Nav --> |Tab 3| ViewPlantsPage[View Plants Page]

    %% 3. Add Plant Flow (Client Requirements)
    subgraph Add Plant Feature
        AddPlantPage --> Form[User Input Form]
        Form --> In1[1. Vegetable Dropdown<br/>Tomato / Eggplant / Siling Labuyo]
        Form --> In2[2. Date Planted<br/>DatePicker]
        Form --> In3[3. Current Stage<br/>Baseline Info]
        Form --> In4[4. Season<br/>Tag-init / Tag-ulan]
        Form --> In5[5. Env Factors<br/>Sunlight / Water / Soil Quality<br/>Mababa / Katamtaman / Mataas]
    end

    %% 4. Backend Core (Cellular Automata & Expert System)
    In1 & In2 & In3 & In4 & In5 --> SaveDB[(Local Database / SQLite)]
    SaveDB --> Engine{Smart Prediction Engine}
    
    subgraph Core Backend Logic
        Engine --> CA[Cellular Automata Model<br/>Grid-based State Simulation]
        CA --> CARules[Apply Rules based on<br/>Env Inputs & Neighborhood Logic]
        
        Engine --> RuleSystem[Rule-Based Expert System]
        RuleSystem --> Thresholds[Evaluate Thresholds<br/>If-Else Conditions]
    end

    %% 5. View Plants Flow & Daily Logs
    subgraph View & Monitor Plants Feature
        ViewPlantsPage --> Grid[List of Added Plants<br/>Clickable Plant Boxes]
        Grid --> PlantStatus[Plant Status View<br/>Shows 3 Things:<br/>1. Predicted Stage<br/>2. Condition Status<br/>3. Recommendations]
        
        CARules --> |Output Stage| PlantStatus
        Thresholds --> |Output Status & Tips| PlantStatus
        
        %% Daily Actions
        PlantStatus --> AddActionBtn[Click 'Add Action' Button]
        AddActionBtn --> ActionForm[Log Daily Care Form]
        ActionForm --> Act1[Select Action<br/>Water / Fertilize / etc.]
        ActionForm --> Act2[Input Quantity<br/>How much water/fertilizer]
        ActionForm --> Act3[Timestamp<br/>Auto-binds to Today's Date]
        
        Act1 & Act2 & Act3 --> SaveLog[(Save to Daily Logs DB)]
        SaveLog --> |Updates Stats| Home
    end

    %% Apply Classes
    class Intro,Home,AddPlantPage,ViewPlantsPage,PlantStatus,ActionForm page;
    class CA,CARules,RuleSystem,Thresholds logic;
    class SaveDB,SaveLog data;