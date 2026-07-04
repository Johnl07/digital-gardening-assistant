Ang Core Idea
Gusto ng client ng mobile app na "digital gardening assistant" para sa vegetable growing (specifically Tomato, Eggplant, at Siling Labuyo). Ang app ay:

Kukuha ng info mula sa user tungkol sa halaman nila
Mag-ppredict kung anong growth stage dapat nasa plant ngayon
Mag-mo-monitor kung healthy ba ang plant base sa conditions
Magbibigay ng tips kung paano pagbutihin ang pag-aalaga

Parang virtual plant doctor + calendar tracker, pero may "smart" prediction engine sa likod gamit ang Cellular Automata.
Breakdown ng Bawat Feature
1. User Input — Simpleng form kung saan ilalagay ng user ang:

Anong gulay (dropdown: Tomato/Eggplant/Siling Labuyo)
Kailan tinanim (date picker)
Current stage ngayon (baseline info)
Season (tag-init/tag-ulan)
Environmental factors: sunlight, water, soil quality (probably ratings/dropdowns — mababa/katamtaman/mataas)

2. Growth Prediction (Cellular Automata) — Ito yung "utak" ng app. Sa halip na simpleng "date-based" na prediction (e.g., "30 days = flowering stage"), gagamit ng grid-based simulation model kung saan:

Bawat "cell" ay may state (growth stage)
May rules na nagde-determine kung kailan mag-a-advance ang stage, base sa environmental inputs (sunlight, water, soil)
Output: predicted stage (Seedling → Young Plant → Flowering → Fruiting)

3. Plant Monitoring — Susuriin ng app kung "healthy" ba yung setup base sa inilagay na factors, at i-flflag kung may kulang (e.g., "Low sunlight detected")
4. Recommendation System — Simpleng rule-based tips na naka-trigger depende sa monitoring result (e.g., kung low sunlight → "Ilipat sa mas maaraw na lugar")
5. Platform — Flutter para pwede sa Android at iOS gamit ang iisang codebase
6. Output — Tatlong bagay lang ipapakita sa user pagkatapos mag-input: predicted stage, condition status, at recommendations
Ibig Sabihin Para Sa Development Team
Ito ay isang capstone-level o academic-style project na kombinasyon ng:

Mobile app development (Flutter/Dart)
Isang simulation/prediction model (Cellular Automata) na kailangan i-design bilang algorithm — kailangan niyo tukuyin ang rules, states, at neighborhood logic
Rule-based expert system para sa recommendations (hindi kailangan ng machine learning, pwedeng if-else logic base sa thresholds)