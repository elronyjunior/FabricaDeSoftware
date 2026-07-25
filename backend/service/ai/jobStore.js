const { randomUUID } = require('crypto');

const JOB_TTL_MS = 30 * 60 * 1000;
const jobs = new Map();

function createJob() {
  const id = randomUUID();
  jobs.set(id, { id, status: 'processing', stage: 'iniciando', createdAt: Date.now() });
  setTimeout(() => jobs.delete(id), JOB_TTL_MS).unref();
  return id;
}

function updateJob(id, patch) {
  const current = jobs.get(id);
  if (!current) return;
  jobs.set(id, { ...current, ...patch });
}

function getJob(id) {
  return jobs.get(id);
}

module.exports = { createJob, updateJob, getJob };
