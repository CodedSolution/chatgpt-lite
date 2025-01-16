# This Dockerfile is generated based on sample in the following document
# https://github.com/vercel/next.js/blob/canary/examples/with-docker/Dockerfile

FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json package-lock.json* ./
RUN npm ci

ARG NEXT_PUBLIC_BACKEND_URL=${NEXT_PUBLIC_BACKEND_URL}
ARG OPENAI_API_URL=${OPENAI_API_URL}
ARG OPENAI_API_KEY=${OPENAI_API_KEY}
ARG OPENAI_API_KEY=${OPENAI_API_KEY}
ARG NEXT_PUBLIC_BACKEND_API_KEY=${NEXT_PUBLIC_BACKEND_API_KEY}

ENV NEXT_PUBLIC_BACKEND_URL=${NEXT_PUBLIC_BACKEND_URL}
ENV OPENAI_API_URL=${OPENAI_API_URL}
ENV OPENAI_API_KEY=${OPENAI_API_KEY}
ENV OPENAI_API_KEY=${OPENAI_API_KEY}
ENV NEXT_PUBLIC_BACKEND_API_KEY=${NEXT_PUBLIC_BACKEND_API_KEY}

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

# ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

# server.js is created by next build from the standalone output
# https://nextjs.org/docs/pages/api-reference/next-config-js/output
CMD HOSTNAME="0.0.0.0" node server.js