# Data IESB — Full Project Audit
> Generated: 2026-04-20 | Purpose: Pre-refactor documentation for agent system migration

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Repository Structure](#2-repository-structure)
3. [Sub-Projects / Components](#3-sub-projects--components)
   - 3.1 [Static Website (Frontend)](#31-static-website-frontend)
   - 3.2 [Chatbot Backend (Flask + Amazon Q Business)](#32-chatbot-backend-flask--amazon-q-business)
   - 3.3 [Team API (Flask + Lambda)](#33-team-api-flask--lambda)
   - 3.4 [Admin Panel](#34-admin-panel)
   - 3.5 [Authentication System](#35-authentication-system)
4. [AWS Infrastructure Map](#4-aws-infrastructure-map)
5. [API Contracts](#5-api-contracts)
6. [Data Models](#6-data-models)
7. [CI/CD Pipeline](#7-cicd-pipeline)
8. [Frontend JS Modules](#8-frontend-js-modules)
9. [Known Issues & Debt](#9-known-issues--debt)
10. [Refactor Target: Agent System Architecture](#10-refactor-target-agent-system-architecture)

---

## 1. Project Overview

**Big Data IESB Platform** — a data analytics platform for Centro Universitário IESB, Brazil.

| Attribute | Value |
|---|---|
| Domain | dataiesb.com |
| Reports App | app.dataiesb.com/report/ |
| Dev Environment | d2v66tm8wx23ar.cloudfront.net |
| Author | Roberto Moreira Diniz |
| Language | Portuguese (pt-BR) |
| Cloud Provider | AWS (primary) |
| Region | sa-east-1 (frontend), us-east-1 (backend) |

**Mission:** Provide public sector, civil society, and academia with an analytical data platform covering health, education, environment, public safety, labor market, public finance, and urban development.

---

## 2. Repository Structure

```
Data-IESB-main/
├── src/                            # All deployable source
│   ├── index.html                  # Homepage — reports + student apps
│   ├── login.html                  # Auth (Cognito + Google OAuth)
│   ├── callback.html               # OAuth callback handler
│   ├── admin.html                  # Admin CRUD panel for reports
│   ├── equipe.html                 # Team page (dynamic DynamoDB data)
│   ├── quem-somos.html             # About us
│   ├── parceiros.html              # Partners
│   ├── contato.html                # Contact
│   ├── miv.html                    # Unknown page (needs investigation)
│   ├── cadastrar.html              # Registration page
│   ├── chatbot_backend.py          # Flask app — Amazon Q Business chatbot
│   ├── team_api.py                 # Flask app — team data (local/dev)
│   ├── lambda_team_api.py          # AWS Lambda — team data (production)
│   ├── requirements.txt            # Python deps (boto3, flask, flask-cors)
│   ├── Dockerfile                  # Container for chatbot_backend
│   ├── apprunner.yaml              # AWS App Runner config
│   ├── Procfile                    # Heroku-style process definition
│   ├── runtime.txt                 # Python runtime spec
│   ├── reports.json                # Legacy static reports data (replaced by DynamoDB)
│   ├── iam-policy.json             # IAM permission policy
│   ├── style/
│   │   ├── home.css                # Main stylesheet
│   │   └── team-dynamic.css        # Team page styles
│   ├── js/
│   │   ├── navigation.js           # Hamburger menu toggle
│   │   ├── qbusiness-chatbot.js    # Chatbot widget (embeddable)
│   │   ├── team-data-api.js        # Team data via REST API (current)
│   │   └── team-data.js            # Team data via AWS SDK direct (legacy)
│   ├── img/                        # Static images
│   └── helm-chart/                 # Kubernetes Helm chart
│       └── Chart.yaml
├── .github/
│   └── workflows/
│       ├── deploy-dev.yml          # CI: push to dev branch → S3 dev
│       └── deploy-prod.yml         # CI: push to prod branch → S3 prod
├── buildspec.yml                   # AWS CodeBuild spec (production)
├── GOOGLE-OAUTH-FIX-GUIDE.md      # Auth troubleshooting guide
└── PROJECT_AUDIT.md               # This file
```

---

## 3. Sub-Projects / Components

### 3.1 Static Website (Frontend)

**Type:** Static HTML/CSS/JS
**Hosting:** Amazon S3 + CloudFront
**Deploy:** GitHub Actions → S3 sync → CloudFront invalidation

#### Pages

| File | Route | Description | Auth Required |
|---|---|---|---|
| `index.html` | `/` | Homepage: hero section, report cards (dynamic), student apps section, newsletter | No |
| `quem-somos.html` | `/quem-somos.html` | About the platform | No |
| `equipe.html` | `/equipe.html` | Team members (fetched from DynamoDB via API) | No |
| `parceiros.html` | `/parceiros.html` | Partners page | No |
| `contato.html` | `/contato.html` | Contact form | No |
| `login.html` | `/login.html` | Login: email/password + Google OAuth (IESB domain only) | No |
| `callback.html` | `/callback.html` | OAuth PKCE code-exchange handler | No |
| `admin.html` | `/admin.html` | Admin panel: CRUD for reports + Python code editor | Yes (JWT) |
| `miv.html` | `/miv.html` | Unknown — needs investigation | ? |
| `cadastrar.html` | `/cadastrar.html` | Registration — needs investigation | ? |

#### Technology Stack
- **CSS Framework:** Custom + Bootstrap 5.3 (on admin only)
- **Font:** Poppins (Google Fonts)
- **Icons:** Bootstrap Icons (admin page)
- **JS:** Vanilla ES6+ (no framework)
- **CDN Assets:** CloudFront (`d28lvm9jkyfotx.cloudfront.net`)

#### Key Frontend Behaviors

**Homepage report cards** (`index.html`):
- Fetches from `GET /prod/dataiesb-auth/public-reports`
- Renders cards sorted by `created_at` DESC, then by `titulo`
- Skips entries where `deletado: true` (already filtered server-side)
- Links to `http://app.dataiesb.com/report/?id={id}`
- Fallback error UI with retry button

**Student apps section** (hardcoded in `index.html`):
- Aurya — NLP public data assistant (`aurya.dataiesb.com`)
- OSINTube-RealTimeGuard — YouTube threat detection (`app.dataiesb.com/osintube`)
- MatrixGym — Matrix determinant trainer (`gym.dataiesb.com`)

---

### 3.2 Chatbot Backend (Flask + Amazon Q Business)

**File:** `src/chatbot_backend.py`
**Runtime:** Python 3.11
**Framework:** Flask + flask-cors
**Container:** `src/Dockerfile`
**Deploy target:** AWS App Runner (`src/apprunner.yaml`)

#### Architecture
```
User → HTTP POST /chat → Flask App → boto3 → Amazon Q Business (chat_sync)
                                   ← systemMessage + sourceAttributions ←
```

#### Endpoints

| Method | Route | Description |
|---|---|---|
| GET | `/` | Health check — returns `{status, service, configured}` |
| POST | `/chat` | Chat — body: `{message, conversationId?}` |
| GET | `/widget` | Serves a standalone HTML chatbot widget |

#### Configuration (env vars)
| Variable | Default | Notes |
|---|---|---|
| `Q_BUSINESS_APPLICATION_ID` | None (required) | Amazon Q Business app ID |
| `Q_BUSINESS_USER_ID` | `default-user` | User context for Q Business |
| `AWS_REGION` | `us-east-1` | AWS region |
| `FLASK_DEBUG` | `False` | Debug mode |
| `PORT` | `5000` | HTTP port |

#### Conversation Handling
- Stateless by default; optionally stateful via `conversationId`
- No authentication on endpoints (CORS open `*`)
- Error wrapping: `ClientError` (AWS) and generic `Exception`

---

### 3.3 Team API (Flask + Lambda)

Two parallel implementations exist:

#### A) Lambda (Production) — `lambda_team_api.py`
- Deployed as AWS Lambda behind API Gateway
- Endpoint: `GET https://hewx1kjfxh.execute-api.us-east-1.amazonaws.com/prod/team`
- Scans `DataIESB-TeamMembers` DynamoDB table
- Returns `{success: true, data: [{id, name, email, role, category, active}]}`
- Handles CORS preflight (OPTIONS)

#### B) Flask (Local/Dev) — `team_api.py`
- Runs on `PORT=5001`
- Same DynamoDB logic as Lambda
- Used for local development only

#### Data Processing
Both normalize the DynamoDB items to:
```json
{
  "id": "<email>",
  "name": "string",
  "email": "string",
  "role": "string",
  "category": "string",
  "active": true
}
```

**Issue:** `id` is set to `email` value — DynamoDB primary key is email, not a separate UUID.

---

### 3.4 Admin Panel

**File:** `src/admin.html`
**Access:** `https://dataiesb.com/admin.html`
**Auth:** JWT `idToken` from `localStorage` (Bearer token in all API calls)

#### Features

| Feature | Description |
|---|---|
| Report Listing | Lists all reports owned by authenticated user |
| Create Report | Form: titulo, autor, descricao + file upload (main.py) |
| Edit Report | Inline form with same fields |
| Delete Report | Soft delete (sets `deletado: true`) |
| Restore Report | Reverses soft delete |
| Code Editor | In-browser textarea editor for `main.py` Streamlit files |
| Code Download | Fetches current Python code from S3 |
| Code Save | PUTs updated code back via API |

#### Admin API Calls (all authenticated via Bearer JWT)
```
GET    /dataiesb-auth/reports          → list user reports
POST   /dataiesb-auth/reports          → create (multipart/form-data)
PUT    /dataiesb-auth/reports/{id}     → update (multipart or JSON)
DELETE /dataiesb-auth/reports/{id}     → soft delete
POST   /dataiesb-auth/reports/{id}/restore → restore
GET    /dataiesb-auth/reports/{id}/download → download main.py from S3
```

#### Code Editor Capabilities
- Tab → 4-space indent
- Ctrl+S → save
- Basic Python syntax highlighting (regex-based)
- Basic bracket balance validation
- Warns on `st.set_page_config()` usage

---

### 3.5 Authentication System

**Provider:** Amazon Cognito
**Domain:** `auth.dataiesb.com`
**Client ID:** `71am2v0jcp9uqpihrh9hjqtp6o`
**Restriction:** `@iesb.edu.br` email domain only

#### Two Auth Flows

**Flow 1 — Email/Password (Cognito User Pools):**
```
User → POST /prod/dataiesb-auth {username, password}
     ← {idToken, message}
→ Store idToken in localStorage
→ Redirect to admin.html
```

**Flow 2 — Google OAuth (Cognito + Google IdP):**
```
User clicks "Entrar com Gmail IESB"
→ Redirect to https://auth.dataiesb.com/oauth2/authorize
  ?client_id=71am2v0jcp9uqpihrh9hjqtp6o
  &identity_provider=Google
  &response_type=code
  &scope=email+openid+profile
  &redirect_uri=.../callback.html
→ callback.html exchanges code for tokens (POST /oauth2/token)
→ Fetches user info (GET /oauth2/userInfo)
→ Validates @iesb.edu.br domain
→ Stores {accessToken, idToken, refreshToken, userInfo} in localStorage
→ Redirect to admin.html
```

#### Security Notes
- JWT validation is client-side only (`atob(token.split('.')[1])`) — not cryptographically verified
- Tokens stored in `localStorage` (XSS risk)
- CORS on API is `*` (open) — should be domain-restricted
- No token refresh mechanism in frontend code

---

## 4. AWS Infrastructure Map

```
Internet
  │
  ├─→ Route 53 (dataiesb.com)
  │     └─→ ACM (SSL/TLS)
  │           └─→ CloudFront (E371T2F886B5KI) [sa-east-1 prod]
  │                 └─→ S3 Bucket: dataiesb [static site]
  │
  ├─→ Route 53 (auth.dataiesb.com)
  │     └─→ Amazon Cognito Hosted UI
  │           └─→ Google Identity Provider
  │
  ├─→ API Gateway (hewx1kjfxh.execute-api.us-east-1.amazonaws.com)
  │     ├─→ POST /prod/dataiesb-auth        → Lambda (auth)
  │     ├─→ GET  /prod/dataiesb-auth/public-reports → Lambda (reports)
  │     ├─→ *    /prod/dataiesb-auth/reports → Lambda (CRUD)
  │     └─→ GET  /prod/team                 → Lambda (team_api)
  │
  ├─→ DynamoDB Tables (us-east-1)
  │     ├─→ DataIESB-TeamMembers  (PK: email)
  │     └─→ dataiesb-reports      (reports metadata)
  │
  ├─→ S3 Buckets
  │     ├─→ dataiesb              (static site)
  │     ├─→ dev-dataiesb          (dev static site)
  │     └─→ dataiesb-reports      (Streamlit main.py files, path: reports/{id}/)
  │
  ├─→ Amazon Q Business
  │     └─→ Application (chatbot knowledge base)
  │
  ├─→ AWS App Runner  (chatbot_backend.py)
  │     └─→ Port 5000 (Flask)
  │
  └─→ EKS Cluster: sas-6881323-eks
        └─→ Load Balancer → Pods (Streamlit report apps)
              └─→ S3 (report data), RDS (structured data)
```

### CloudFront Distributions
| Distribution ID | Domain | Purpose |
|---|---|---|
| E371T2F886B5KI | dataiesb.com | Production |
| E142Z1CPAKR8S8 | d2v66tm8wx23ar.cloudfront.net | Development |

---

## 5. API Contracts

**Base URL:** `https://hewx1kjfxh.execute-api.us-east-1.amazonaws.com/prod`

### Public Endpoints (no auth)

#### GET /team
Returns all team members.
```json
Response 200:
{
  "success": true,
  "data": [
    {
      "id": "email@iesb.edu.br",
      "name": "Full Name",
      "email": "email@iesb.edu.br",
      "role": "Job Title",
      "category": "Category Name",
      "active": true
    }
  ]
}
```

#### GET /dataiesb-auth/public-reports
Returns all non-deleted reports.
```json
Response 200:
{
  "report-id": {
    "titulo": "Report Title",
    "descricao": "Description",
    "autor": "Author Name",
    "created_at": "ISO date string"
  }
}
```

### Authenticated Endpoints (Bearer JWT required)

#### POST /dataiesb-auth
Login with email/password.
```json
Request:  { "username": "user@iesb.edu.br", "password": "..." }
Response: { "message": "...", "idToken": "jwt..." }
```

#### GET /dataiesb-auth/reports
List reports for authenticated user.

#### POST /dataiesb-auth/reports
Create report (multipart/form-data).
```
Fields: titulo, autor, descricao, main (file: .py)
```

#### PUT /dataiesb-auth/reports/{id}
Update report. Accepts multipart/form-data or JSON.
```json
JSON body: { "titulo": "...", "autor": "...", "descricao": "...", "code": "python code string" }
```

#### DELETE /dataiesb-auth/reports/{id}
Soft delete (sets `deletado: true`).

#### POST /dataiesb-auth/reports/{id}/restore
Restore soft-deleted report.

#### GET /dataiesb-auth/reports/{id}/download
Returns raw Python file (binary/octet-stream or text).

---

## 6. Data Models

### DynamoDB: DataIESB-TeamMembers
| Attribute | Type | Notes |
|---|---|---|
| `email` | String (PK) | Primary key |
| `name` | String | Full name |
| `role` | String | Job title |
| `category` | String | Group: Coordenação, Equipe Técnica, etc. |
| `linkedin` | String | LinkedIn URL (optional) |
| `escavador` | String | Escavador.com URL (optional) |

### DynamoDB: dataiesb-reports
| Attribute | Type | Notes |
|---|---|---|
| `id` | String (PK) | Report ID |
| `titulo` | String | Report title |
| `descricao` | String | Description |
| `autor` | String | Author name |
| `deletado` | Boolean | Soft delete flag |
| `hidden` | Boolean | Hidden from public |
| `created_at` | String | ISO datetime |
| `id_s3` | String | S3 path prefix (e.g., `reports/1/`) |

### S3: dataiesb-reports
```
reports/
  {id}/
    main.py     ← Streamlit dashboard Python file
```

---

## 7. CI/CD Pipeline

### GitHub Actions Workflows

#### `deploy-dev.yml` — triggered on push to `dev` branch
```
push to dev →
  Checkout code
  Configure AWS credentials (secrets)
  aws s3 sync src/ s3://dev-dataiesb/ --delete
  CloudFront invalidate E142Z1CPAKR8S8 /*
  → Dev URL: https://d2v66tm8wx23ar.cloudfront.net
```

#### `deploy-prod.yml` — triggered on push to `prod` branch
```
push to prod →
  Checkout code
  Configure AWS credentials (secrets)
  aws s3 sync src/ s3://dataiesb/ --delete
  CloudFront invalidate production distribution /*
  → Prod URL: https://dataiesb.com
```

### AWS CodeBuild (`buildspec.yml`)
Alternative/complementary build for main branch:
- Region: `sa-east-1`
- S3 Bucket: `dataiesb`
- CloudFront: `E371T2F886B5KI`
- Excludes: `.sh`, `.json`, `.git/*`, `.github/*`, `*.md`, `test-*`, `*-test.*`

### Secrets Required
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

## 8. Frontend JS Modules

### `js/navigation.js`
Hamburger menu toggle. Closes menu on outside click or nav link click (mobile only, `≤992px`).

### `js/qbusiness-chatbot.js` — Class: `QBusinessChatbot`
Embeddable chatbot widget. Configurable via constructor options:
```js
new QBusinessChatbot({
  apiUrl: 'http://localhost:5000',   // chatbot_backend.py URL
  title: 'Assistente Q Business',
  welcomeMessage: '...',
  placeholder: '...',
  primaryColor: '#232F3E',
  accentColor: '#007DBA',
  position: 'bottom-right'          // bottom-right|bottom-left|top-right|top-left
})
```
- Auto-initializes if `window.qbChatbotConfig` is defined
- Maintains `conversationId` for multi-turn chat
- Typing indicator (3-dot animation)
- Responsive: full-screen on mobile

### `js/team-data-api.js` — Class: `TeamDataManager` (current)
Fetches team members from REST API:
```
localhost/127.0.0.1 → http://localhost:5001/api/team
all other → https://hewx1kjfxh.execute-api.us-east-1.amazonaws.com/prod/team
```
- Groups by category: `Coordenação` → `Equipe Técnica`
- Shows LinkedIn for `Equipe Técnica`, Escavador for `Coordenação`
- Hardcoded fallback data (11 members) if API fails

### `js/team-data.js` — Class: `TeamDataManager` (legacy/alternative)
Direct AWS SDK access to DynamoDB (Cognito Identity Pool — **not configured**, placeholder `'us-east-1:your-identity-pool-id'`). Falls back to static data. Not in active use.

**Issue:** Two files export the same class name `TeamDataManager` — the active one is `team-data-api.js`.

---

## 9. Known Issues & Debt

### Security
- [ ] JWT validated client-side only (no signature verification)
- [ ] Tokens in `localStorage` (vulnerable to XSS)
- [ ] CORS `Access-Control-Allow-Origin: *` on Lambda
- [ ] Admin page has no server-side domain check beyond JWT claim
- [ ] `team-data.js` has hardcoded placeholder Identity Pool ID

### Architecture
- [ ] Duplicate `TeamDataManager` class in two JS files
- [ ] `reports.json` (static) is dead code — replaced by DynamoDB API
- [ ] `team-data.js` (direct SDK) is dead code — replaced by `team-data-api.js`
- [ ] Two parallel team API implementations (Flask + Lambda) for same data
- [ ] Inline JavaScript in HTML files (index.html, login.html, callback.html)
- [ ] No state management — all state in `localStorage`
- [ ] No API versioning on backend
- [ ] Cognito Client ID hardcoded in frontend HTML

### Operational
- [ ] `apprunner.yaml` has `Q_BUSINESS_APPLICATION_ID: "your-app-id-here"` (unconfigured)
- [ ] `team-data.js` Identity Pool ID is a placeholder
- [ ] Newsletter form (`index.html`) has no backend wired up
- [ ] Search input in nav is commented out
- [ ] Two different CI pipelines (GitHub Actions + CodeBuild) for same deployment target
- [ ] `miv.html` and `cadastrar.html` not audited

### Code Quality
- [ ] Admin code editor uses basic regex for Python syntax highlighting
- [ ] Admin Python formatter is custom/naive (not using Black/autopep8)
- [ ] No error boundary pattern — errors surface as raw text
- [ ] No loading state management pattern (ad-hoc per page)

---

## 10. Refactor Target: Agent System Architecture

### Current vs Target State

| Layer | Current | Target |
|---|---|---|
| Frontend | Static HTML + vanilla JS | SPA (React/Next.js) with component architecture |
| Backend | Flask + Lambda (fragmented) | FastAPI or LangServe with agent orchestration |
| AI | Amazon Q Business (single chatbot) | Multi-agent system (specialized agents per domain) |
| Auth | Manual JWT + localStorage | Proper OAuth PKCE + secure token storage |
| State | Ad-hoc per page | Centralized state management |
| API | Single API Gateway (mixed concerns) | Versioned REST + WebSocket for agent streaming |
| Data | DynamoDB + S3 (direct) | Abstracted data layer with caching |
| Infra | Manual Lambda + EKS | Infrastructure as Code (Terraform/CDK) |

### Identified Agent Opportunities

Based on existing functionality, the following agents should be built:

1. **Report Agent** — manages lifecycle of Streamlit reports (create, edit, publish, archive)
2. **Team Agent** — manages team member data in DynamoDB
3. **Data Query Agent** — answers questions about public data (extends Q Business)
4. **Auth Agent** — handles login, token refresh, domain validation
5. **Content Agent** — manages homepage content, panels, and news
6. **Admin Orchestrator** — routes admin commands to appropriate agents

### Entry Points for Refactor

**Backend (priority order):**
1. Consolidate `lambda_team_api.py` + `team_api.py` into single service
2. Migrate Auth Lambda to proper OAuth 2.0 server with PKCE
3. Create unified agent router (FastAPI + LangGraph/LangChain)
4. Replace Amazon Q Business with custom RAG or Bedrock Agents
5. Add WebSocket endpoint for streaming agent responses

**Frontend (priority order):**
1. Extract inline JS from HTML into modules
2. Migrate to component-based framework (React/Next.js recommended)
3. Replace `localStorage` token storage with `httpOnly` cookies or secure PKCE flow
4. Implement proper routing (React Router or Next.js pages)
5. Add centralized state management (Zustand or Redux)
6. Create reusable UI component library

### Domains / Bounded Contexts
```
┌─────────────────────────────────────────────────────┐
│                  Data IESB Platform                  │
├───────────────┬──────────────┬──────────────────────┤
│   Public Site │  Admin Panel │    Agent System       │
│               │              │                       │
│  - Reports    │  - CRUD      │  - Report Agent       │
│  - Team       │  - Code Edit │  - Team Agent         │
│  - Partners   │  - Auth      │  - Query Agent        │
│  - Student    │              │  - Content Agent      │
│    Apps       │              │  - Orchestrator       │
└───────────────┴──────────────┴──────────────────────┘
```
