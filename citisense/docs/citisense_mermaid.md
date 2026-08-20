# CitiSense Editable Mermaid Diagrams

Copy the code blocks below and paste them into [Mermaid Live Editor](https://mermaid.live/) or any Mermaid-compatible tool (like Notion or Figma plugins) to instantly generate perfectly spaced, fully editable diagrams!

---

### Figure 3.6: Gantt Chart

```mermaid
gantt
    title Figure 3.6. Gantt Chart - CitiSense Software Development Process Schedule
    dateFormat  YYYY-MM-DD
    axisFormat  W%W
    
    section 1. Planning Phase
    Requirements Gathering & Scoping :active, p1, 2024-01-01, 14d
    
    section 2. Design Phase
    Architecture, UI/UX, & DFDs      :active, d1, 2024-01-15, 14d
    
    section 3. Development Phase
    Mobile App & Admin Dashboard     :active, dev1, 2024-01-29, 42d
    
    section 4. Testing Phase
    Functional Testing & Validation  :active, t1, 2024-03-11, 14d
    
    section 5. Evaluation Phase
    Quality & Security Assessment    :active, e1, 2024-03-25, 7d
    
    section 6. Deployment Phase
    Release & User Training          :active, dep1, 2024-04-01, 7d
```

---

### Figure 3.2: System Architecture Diagram

```mermaid
flowchart TD
    subgraph Client Layer
        C[Citizen Mobile App<br>Mobile Feedback Form, Image Upload]
        B[Barangay Web Portal<br>Sentiment Stats, Feedback Console]
        A[Admin Maintenance Console<br>User Management, System Configs]
    end

    subgraph Service Layer
        S[Core Application Server<br>Route Handlers, State Management]
    end

    subgraph Core Engines Layer
        SE[Sentiment Analysis Engine<br>Naïve Bayes Classifier]
        RE[Recommendation Engine<br>Rule-Based Mapper]
    end

    subgraph Data Layer
        DB[(Database Storage<br>Users, Feedbacks, Sentiment Logs)]
    end

    C -- "Submit Feedback (Signal: Message Text)" --> S
    S -- "Sentiment & Recommendation Result" --> C
    
    B <-- "Query Stats / Update Status Action" --> S
    A <-- "Update System Rules / Audit Logs" --> S

    S -- "Send Text" --> SE
    SE -- "Return Class" --> S

    S <-- "Get Recommendation" --> RE
    
    S <-- "Read / Write Data" --> DB
```

---

### Figure 3.3: Use Case Diagram (with 3 Actors!)

```mermaid
usecaseDiagram
    actor "Users (Citizens)" as U
    actor "Barangay Officials\n(Monitoring & Management)" as B
    actor "System Admin\n(Fixing & Maintenance)" as A

    package "CitiSense System Boundary" {
        usecase "UC1: Create Account / Log In" as UC1
        usecase "UC2: Submit Community Feedback\n(Category, Message, Image)" as UC2
        usecase "UC3: View Sentiment Analysis &\nSystem Recommendation Results" as UC3
        usecase "UC4: Monitor Statistics Dashboard\n(Real-Time Community Metrics)" as UC4
        usecase "UC5: Manage Pending Feedbacks\n(Resolve or Ignore Logs)" as UC5
        usecase "UC6: Manage User Access Control &\nSystem Configurations" as UC6
        usecase "UC7: Review System Error Logs &\nPerform Database Backups" as UC7
    }

    U --> UC1
    U --> UC2
    U --> UC3

    B --> UC1
    B --> UC4
    B --> UC5

    A --> UC1
    A --> UC6
    A --> UC7
```

---

### Figure 3.4: DFD Level 0 (Context Diagram)

```mermaid
flowchart LR
    Citizen[Citizen]
    Official[Barangay Official<br>Monitoring & Mgmt]
    Admin[System Admin<br>Fixing & Maintenance]
    
    System((0.0<br>CitiSense Urban Feedback<br>Intelligence System))
    
    Citizen -- "1. Signup / Login Credentials<br>2. Submit Feedback (Text, Category, Image)" --> System
    System -- "1. Sentiment Result & Recommendation<br>2. Feedback Action Status Updates" --> Citizen
    
    Official -- "1. Login Credentials<br>2. Feedback Resolve/Ignore Action" --> System
    System -- "1. Dashboard Sentiment Statistics<br>2. Detail Feedback Log List" --> Official
    
    Admin -- "1. Admin Credentials<br>2. System Configs & Access Rules" --> System
    System -- "1. Security Backups<br>2. System Error Logs reports" --> Admin
```

---

### Figure 3.5: DFD Level 1

```mermaid
flowchart TD
    Citizen[Citizen]
    Official[Barangay Official<br>Monitoring]
    Admin[System Admin<br>Maintenance]
    
    P1((1.0<br>User<br>Authentication))
    P2((2.0<br>Feedback<br>Management))
    P3((3.0<br>Sentiment &<br>Recommendation Engine))
    P4((4.0<br>Feedback Monitoring<br>& Dashboards))
    P5((5.0<br>System Administration<br>& Maintenance))
    
    D1[(D1: Users Data Store)]
    D2[(D2: Feedback Database)]
    
    %% Auth
    Citizen -- "Login Credentials" --> P1
    Official -- "Login Credentials" --> P1
    Admin -- "Login Credentials" --> P1
    P1 <-- "Verify / Save User" --> D1
    
    %% Citizen Feedback Submission
    Citizen -- "Submit Feedback" --> P2
    P2 -- "Display Sentiment & Recommendation" --> Citizen
    P2 -- "Write Feedback (Pending)" --> D2
    
    %% Core Engines
    P2 -- "Send Message Text" --> P3
    P3 -- "Return Score & Recommendation" --> P2
    
    %% Barangay Official Monitoring
    Official -- "Resolve / Ignore Feedbacks" --> P4
    P4 -- "Display Stats & Trend Reports" --> Official
    P4 <-- "Fetch & Update Status" --> D2
    
    %% Admin Maintenance
    Admin -- "Configure Access Rules" --> P5
    P5 -- "Activity / Error logs" --> Admin
    P5 <-- "Manage D1 Profiles" --> D1
    P5 <-- "Backup D2 Audits" --> D2
```
