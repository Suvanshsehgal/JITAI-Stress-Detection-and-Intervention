# Ebb JITAI Backend

FastAPI backend service supporting Phase 9 Real ML & Remote Backend Integration.

## Architecture

- **Framework**: FastAPI (Python 3.12)
- **API Versioning**: `/api/v1/...`
- **Security**: JWT Authentication, PBKDF2 password hashing, CORS protection, privacy-safe logging (no raw physiological metrics or sensitive user payloads logged).
- **Stress Detection Adapter**: `StrideProbeStressAdapter` integrates the composite stress model contract (from Stride Probe) through an external adapter boundary without modifying `stressdata/`.
- **JITAI Decision Engine**: Server-side policy evaluating stress assessments, context (calendar busy/free suppression), cooldowns (15-min window), and idempotency keys.
- **Intervention Response Sync**: Idempotent synchronization of user responses (`accepted`, `declined`, `dismissed`, `completed`, `abandoned`).

## Endpoints

- `GET /health` / `GET /api/v1/health` - Service healthcheck
- `POST /api/v1/auth/register` - Register a user
- `POST /api/v1/auth/login` - Authenticate user
- `GET /api/v1/auth/me` - Get authenticated user profile
- `POST /api/v1/stress/assess` - Stress assessment from ContextSnapshot
- `POST /api/v1/jitai/evaluate` - JITAI intervention evaluation
- `POST /api/v1/sync/interventions` - Idempotent sync of intervention responses
- `GET /api/v1/sync/history` - Retrieve synced intervention history
