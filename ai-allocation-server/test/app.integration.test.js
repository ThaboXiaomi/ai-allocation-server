const test = require("node:test");
const assert = require("node:assert/strict");

const { createApp } = require("../index");

async function withServer(app, fn) {
  const server = app.listen(0);
  await new Promise((resolve) => server.once("listening", resolve));
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;
  try {
    await fn(baseUrl);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test("auth middleware blocks unauthorized access when API_AUTH_TOKEN is set", async () => {
  process.env.API_AUTH_TOKEN = "secret";
  const app = createApp({ db: {} });

  await withServer(app, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/health`);
    assert.equal(response.status, 401);
    const body = await response.json();
    assert.equal(body.error.code, "UNAUTHORIZED");
    assert.ok(body.error.requestId);
  });

  delete process.env.API_AUTH_TOKEN;
});

test("GET /allocations applies limit and returns paged envelope", async () => {
  const mockDocs = Array.from({ length: 3 }).map((_, i) => ({
    id: `id-${i + 1}`,
    data: () => ({ name: `Allocation ${i + 1}` }),
  }));

  const db = {
    collection(name) {
      assert.equal(name, "allocations");
      return {
        limit(limitValue) {
          assert.equal(limitValue, 2);
          return {
            async get() {
              return { docs: mockDocs.slice(0, 2) };
            },
          };
        },
      };
    },
  };

  const app = createApp({ db });
  await withServer(app, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/allocations?limit=2`);
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.limit, 2);
    assert.equal(body.count, 2);
    assert.equal(body.items.length, 2);
  });
});

test("POST /resolve-conflict returns BAD_REQUEST envelope for invalid payload", async () => {
  const db = {
    runTransaction: async () => {},
    collection: () => ({
      doc: () => ({}),
    }),
  };

  const app = createApp({ db });

  await withServer(app, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/resolve-conflict`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ allocationId: "abc" }),
    });

    assert.equal(response.status, 400);
    const body = await response.json();
    assert.equal(body.error.code, "BAD_REQUEST");
    assert.match(body.error.message, /Missing required fields/);
  });
});
