const test = require("node:test");
const assert = require("node:assert/strict");

const {
  parseTime12h,
  validateResolveConflictPayload,
  validateEnv,
  buildError,
} = require("../index");

test("parseTime12h parses valid 12-hour times", () => {
  assert.equal(parseTime12h("12:00 AM"), 0);
  assert.equal(parseTime12h("12:00 PM"), 720);
  assert.equal(parseTime12h("1:30 PM"), 810);
});

test("parseTime12h rejects invalid values", () => {
  assert.equal(parseTime12h("10:00"), null);
  assert.equal(parseTime12h("13:00 PM"), null);
});

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

test("validateResolveConflictPayload rejects invalid time format", () => {
  const result = validateResolveConflictPayload({
    allocationId: "a1",
    date: "2025-07-09",
    startTime: "10:00",
    endTime: "12:00",
  });
  assert.equal(result.valid, false);
  assert.match(result.message, /Invalid time format/);
});

test("validateResolveConflictPayload rejects end before start", () => {
  const result = validateResolveConflictPayload({
    allocationId: "a1",
    date: "2025-07-09",
    startTime: "02:00 PM",
    endTime: "01:00 PM",
  });
  assert.equal(result.valid, false);
  assert.match(result.message, /endTime must be later/);
});

test("validateResolveConflictPayload accepts valid payload", () => {
  const result = validateResolveConflictPayload({
    allocationId: "a1",
    date: "2025-07-09",
    startTime: "10:00 AM",
    endTime: "12:00 PM",
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

test("buildError returns standardized error contract", () => {
  const err = buildError("BAD_REQUEST", "Oops", "details", "req-123");
  assert.deepEqual(err, {
    error: {
      code: "BAD_REQUEST",
      message: "Oops",
      details: "details",
      requestId: "req-123",
    },
  });
});
