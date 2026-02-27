const test = require("node:test");
const assert = require("node:assert/strict");

const {
  validateResolveConflictPayload,
  validateEnv,
} = require("../index");

test("validateResolveConflictPayload rejects non-object input", () => {
  const result = validateResolveConflictPayload(null);
  assert.equal(result.valid, false);
  assert.match(result.message, /JSON object/);
});

test("validateResolveConflictPayload rejects missing required fields", () => {
  const result = validateResolveConflictPayload({ allocationId: "a1" });
  assert.equal(result.valid, false);
  assert.match(result.message, /date/);
  assert.match(result.message, /startTime/);
  assert.match(result.message, /endTime/);
});

test("validateResolveConflictPayload accepts valid payload", () => {
  const result = validateResolveConflictPayload({
    allocationId: "a1",
    date: "2025-07-09",
    startTime: "10:00",
    endTime: "12:00",
  });

  assert.deepEqual(result, { valid: true });
});

test("validateEnv returns false when required env vars are missing", () => {
  const previous = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  delete process.env.GOOGLE_APPLICATION_CREDENTIALS;

  const logger = {
    error: () => {},
    warn: () => {},
  };

  const isValid = validateEnv(logger);
  assert.equal(isValid, false);

  if (previous !== undefined) {
    process.env.GOOGLE_APPLICATION_CREDENTIALS = previous;
  }
});
