# BeMyGuide Backend

Cloudflare Workers backend for the BeMyGuide Flutter app with anonymous authentication and rate limiting.

## 🚀 Quick Start

### Local Development

```bash
npm install
npm run dev
```

### Docker Development

For a consistent development environment with all dependencies pre-installed:

```bash
# Start backend development server
docker-compose up backend-dev

# Or run in detached mode
docker-compose up -d backend-dev

# Access interactive shell for debugging
docker-compose run backend-shell bash

# View logs
docker-compose logs -f backend-dev
```

The backend will be available at `http://localhost:8787`

### Docker Services

- **backend-dev**: Runs `wrangler dev` with hot reload
- **backend-shell**: Interactive container for debugging and manual commands

## 🚀 Deployment

```bash
npm run deploy
```

## 🔧 Development Commands

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Deploy to Cloudflare
npm run deploy

# Generate TypeScript types
npm run cf-typegen

# Run tests
npm run test
```

## 🐳 Docker Commands

```bash
# Build and start backend development
docker-compose up backend-dev

# Rebuild backend image
docker-compose build backend-dev

# Run interactive shell
docker-compose run backend-shell bash

# Stop all services
docker-compose down

# Clean up volumes
docker-compose down -v
```

## 📁 Project Structure

```
backend/
├── src/
│   ├── index.js          # Main Workers entry point
│   ├── auth/             # Authentication middleware
│   └── routes/           # API route handlers
├── wrangler.toml         # Workers configuration
├── package.json          # Dependencies
├── Dockerfile.dev        # Development Docker image
└── README.md
```

## ⚙️ Configuration

Pass the `CloudflareBindings` as generics when instantiating `Hono`:

```ts
// src/index.ts
const app = new Hono<{ Bindings: CloudflareBindings }>()
```

## 🔑 Environment Setup

1. Login to Cloudflare: `wrangler login`
2. Create KV namespaces:
   ```bash
   wrangler kv:namespace create "RATE_LIMITER"
   wrangler kv:namespace create "USER_SESSIONS"
   ```
3. Update `wrangler.toml` with your namespace IDs
4. Deploy: `wrangler deploy`

## 🛠️ Docker Setup Details

The Docker setup uses:
- **Latest Node.js**: Always up-to-date Node.js LTS
- **Wrangler CLI**: Pre-installed globally
- **User Mapping**: Container user matches your host UID/GID to prevent permission issues
- **Volume Mount**: Backend folder mounted to `/workspace` in container
