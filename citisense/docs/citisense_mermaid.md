# CitiSense Editable Mermaid Diagrams

Copy the code blocks below and paste them into [Mermaid Live Editor](https://mermaid.live/) or any Mermaid-compatible tool (like Notion or Figma plugins) to instantly generate perfectly spaced, fully editable diagrams!

---

### Figure 3.2: System Architecture Diagram

```mermaid
flowchart TD
    subgraph Mobile["Flutter Mobile App (CitiSense)"]
        direction TB
        subgraph Screens["Role-Based Screens"]
            C[Citizen<br>Home, Report Issue,<br>My Reports]
            O[Barangay Official<br>Dashboard, Complaints Feed]
            A[System Admin<br>Dashboard, Users,<br>Complaints, Audit Logs]
        end

        subgraph State["State Management"]
            AS[AppState<br>ChangeNotifier + Provider<br>Auth, Complaints, Users, Logs]
        end

        subgraph Engines["Core Services"]
            SE[Sentiment Engine<br>Taglish Lexicon v3<br>EN + Filipino + Negation]
            CS[Camera Service<br>image_picker +<br>permission_handler]
            LS[Location Service<br>geolocator +<br>flutter_map]
        end
    end

    subgraph Repo["Repository Layer (Abstraction)"]
        R[AppRepository<br>Abstract Interface]
        subgraph Impl["Implementations"]
            MR[MockRepository<br>In-Memory Demo Data<br>Works Offline]
            FR[FirebaseRepository<br>Firebase Auth +<br>Cloud Firestore + Storage]
        end
    end

    subgraph Data["Data Stores"]
        MD[(Mock Data<br>5 Users, 10 Complaints,<br>3 Audit Logs)]
        FB[(Google Firebase<br>Auth, Firestore,<br>Storage)]
    end

    C & O & A --> AS
    AS --> SE
    AS --> CS
    AS --> LS
    AS --> R
    R --> MR
    R --> FR
    MR --> MD
    FR --> FB
```

---

### Figure 3.3: Use Case Diagram

```mermaid
usecaseDiagram
    actor "Citizen" as C
    actor "Barangay Official" as O
    actor "System Admin" as A

    package "CitiSense Native Flutter App" {
        usecase "UC1: Create Account / Log In" as UC1
        usecase "UC2: Submit Complaint\n(Category, Description, Evidence Photo,\nMap Pin Location)" as UC2
        usecase "UC3: View Sentiment Analysis\n& Auto-Recommendation" as UC3
        usecase "UC4: Track Complaint Status\n(With Status Timeline)" as UC4
        usecase "UC5: View Dashboard Statistics\n(Charts & Metrics)" as UC5
        usecase "UC6: Acknowledge Complaint" as UC6
        usecase "UC7: Resolve Complaint\n(Upload Proof Photo)" as UC7
        usecase "UC8: Reject Complaint\n(Provide Reason)" as UC8
        usecase "UC9: Manage Users\n(Add Officer, Revoke/Restore)" as UC9
        usecase "UC10: View All Complaints\n(Delete if needed)" as UC10
        usecase "UC11: View Audit Logs" as UC11
        usecase "UC12: Change Theme\n(Light/Dark/System, High Contrast)" as UC12
        usecase "UC13: View Privacy Policy" as UC13
    }

    C --> UC1
    C --> UC2
    C --> UC3
    C --> UC4
    C --> UC12
    C --> UC13

    O --> UC1
    O --> UC5
    O --> UC6
    O --> UC7
    O --> UC8
    O --> UC12
    O --> UC13

    A --> UC1
    A --> UC5
    A --> UC9
    A --> UC10
    A --> UC11
    A --> UC12
    A --> UC13
```

---

### Figure 3.4: DFD Level 0 (Context Diagram)

```mermaid
flowchart LR
    Citizen[Citizen]
    Official[Barangay Official<br>Monitoring & Resolution]
    Admin[System Admin<br>User & System Mgmt]

    System((0.0 CitiSense<br>Native Flutter App<br>Calamba City))

    Citizen -- "1. Signup / Login Credentials\n2. Submit Complaint\n   (Category, Description,\n    Evidence Photo, Map Coordinates)" --> System
    System -- "1. Sentiment Result & Recommendation\n2. Complaint Status Updates\n3. Privacy Policy" --> Citizen

    Official -- "1. Login Credentials\n2. Acknowledge / Resolve (Proof Photo)\n   / Reject (Reason)" --> System
    System -- "1. Complaint Feed & Filters\n2. Dashboard Statistics\n3. Complaint Detail + Map" --> Official

    Admin -- "1. Admin Credentials\n2. Add/Revoke Officers\n3. Delete Complaints" --> System
    System -- "1. System Dashboard (Charts)\n2. User Management\n3. Audit Logs" --> Admin
```

---

### Figure 3.5: DFD Level 1

```mermaid
flowchart TD
    Citizen[Citizen]
    Official[Barangay Official<br>Monitoring]
    Admin[System Admin<br>Maintenance]

    P1((1.0 User<br>Authentication))
    P2((2.0 Complaint<br>Submission))
    P3((3.0 Sentiment &<br>Recommendation Engine))
    P4((4.0 Complaint Monitoring<br>& Resolution))
    P5((5.0 System Administration<br>& Maintenance))

    D1[(D1: Users<br>Data Store)]
    D2[(D2: Complaints<br>Data Store)]
    D3[(D3: Audit Logs<br>Data Store)]

    Citizen -- "Login Credentials" --> P1
    Official -- "Login Credentials" --> P1
    Admin -- "Login Credentials" --> P1
    P1 <-- "Verify / Create User" --> D1

    Citizen -- "Description, Category,\nEvidence Photo,\nMap Coordinates" --> P2
    P2 -- "Sentiment Score &\nRecommendation" --> Citizen
    P2 -- "Write Complaint (Pending)" --> D2

    P2 -- "Description Text" --> P3
    P3 -- "Sentiment + Recommendation" --> P2

    Official -- "Acknowledge / Resolve\n(Proof Photo) / Reject" --> P4
    P4 -- "Complaint List,\nDashboard Stats,\nDetail View" --> Official
    P4 <-- "Read / Update Complaint" --> D2
    P4 -- "Log Action" --> D3

    Admin -- "Manage Users,\nDelete Complaints" --> P5
    P5 -- "User List,\nAll Complaints,\nAudit Logs" --> Admin
    P5 <-- "Read / Write Users" --> D1
    P5 <-- "Read / Delete Complaints" --> D2
    P5 <-- "Read Logs" --> D3
```

---

### Figure 3.6: Gantt Chart

```mermaid
gantt
    title Figure 3.6. Gantt Chart - CitiSense Software Development Process Schedule
    dateFormat  YYYY-MM-DD
    axisFormat  %b %d

    section 1. Planning Phase
    Requirements Gathering & Scoping     :active, p1, 2026-06-01, 14d

    section 2. Design Phase
    Architecture, UI/UX, & DFDs          :active, d1, 2026-06-15, 14d

    section 3. Development Phase
    Core App (Auth, Citizen, Officer)    :active, dev1, 2026-06-29, 21d
    Admin Dashboard & User Mgmt          :active, dev2, after dev1, 14d
    Sentiment Engine & ML Pipeline       :active, dev3, after dev2, 10d
    Theme System & UI Polish             :active, dev4, after dev3, 7d
    Firebase Integration & Map Picker    :active, dev5, after dev4, 7d

    section 4. Testing Phase
    Functional Testing & Validation      :active, t1, after dev5, 10d

    section 5. Documentation Phase
    Paper Writing & Diagrams             :active, doc1, after t1, 14d

    section 6. Deployment Phase
    Release APK & User Training          :active, dep1, after doc1, 7d
```
