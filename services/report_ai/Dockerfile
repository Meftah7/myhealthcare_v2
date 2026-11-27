FROM node:24.13.0-alpine
WORKDIR /app
COPY --chown=node:node services/report_ai/server.mjs services/report_ai/assistant.mjs services/report_ai/medical_policy.mjs services/report_ai/config.mjs ./report_ai/
COPY --chown=node:node services/shared_api/ai.mjs ./shared_api/
USER node
ENV HOST=0.0.0.0 PORT=8790 REPORT_AI_REQUIRE_PROVIDER=true
EXPOSE 8790
CMD ["node", "report_ai/server.mjs"]
