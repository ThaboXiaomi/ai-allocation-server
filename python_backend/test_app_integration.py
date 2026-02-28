import importlib

import importlib.util
import os
import pathlib
import sys
import tempfile
import types
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))


class _FakeDoc:
    def __init__(self, doc_id, data=None):
        self.id = doc_id
        self._data = data or {}

    def to_dict(self):
        return self._data


class _FakeStreamQuery:
    def __init__(self, docs):
        self._docs = docs

    def limit(self, n):
        return _FakeStreamQuery(self._docs[:n])

    def stream(self):
        return iter(self._docs)


class _FakeCollection:
    def __init__(self, name, docs_map):
        self.name = name
        self.docs_map = docs_map

    def limit(self, n):
        docs = list(self.docs_map.get(self.name, []))[:n]
        return _FakeStreamQuery(docs)

    def where(self, _field, _op, _value):
        return _FakeStreamQuery([])


class _FakeDb:
    def __init__(self):
        self.docs_map = {
            "allocations": [
                _FakeDoc("a1", {"course": "CSC101", "status": "pending"}),
                _FakeDoc("a2", {"course": "MTH201", "status": "pending"}),
            ]
        }

    def collection(self, name):
        return _FakeCollection(name, self.docs_map)


class _FakeFirestoreClient:
    @staticmethod
    def from_service_account_json(_path):
        return _FakeDb()


def _install_dependency_stubs():
    if "google" not in sys.modules:
        google_module = types.ModuleType("google")
        cloud_module = types.ModuleType("google.cloud")
        firestore_module = types.ModuleType("google.cloud.firestore")
        firestore_module.Client = _FakeFirestoreClient
        firestore_module.SERVER_TIMESTAMP = object()

        google_module.cloud = cloud_module
        cloud_module.firestore = firestore_module

        sys.modules["google"] = google_module
        sys.modules["google.cloud"] = cloud_module
        sys.modules["google.cloud.firestore"] = firestore_module

    if "openai" not in sys.modules:
        openai_module = types.ModuleType("openai")
        openai_module.api_key = None
        openai_module.chat = types.SimpleNamespace(completions=types.SimpleNamespace(create=lambda **_kwargs: None))
        sys.modules["openai"] = openai_module


HAS_FLASK_DEPS = importlib.util.find_spec("flask") is not None and importlib.util.find_spec("dotenv") is not None


@unittest.skipUnless(HAS_FLASK_DEPS, "Flask/python-dotenv dependencies are required for integration tests")
class AppIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp_creds = tempfile.NamedTemporaryFile(delete=False)
        cls.temp_creds.close()

    @classmethod
    def tearDownClass(cls):
        os.unlink(cls.temp_creds.name)

    def _load_app_module(self, auth_token=None):
        _install_dependency_stubs()

        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = self.temp_creds.name
        os.environ["APP_ENV"] = "development"
        os.environ["OPENAI_API_KEY"] = ""
        if auth_token:
            os.environ["API_AUTH_TOKEN"] = auth_token
        else:
            os.environ.pop("API_AUTH_TOKEN", None)

        if "app" in sys.modules:
            del sys.modules["app"]

        return importlib.import_module("app")

    def test_health_includes_request_id_header(self):
        app_module = self._load_app_module()
        client = app_module.create_app().test_client()

        response = client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertIn("X-Request-Id", response.headers)
        self.assertEqual(response.json["requestId"], response.headers["X-Request-Id"])

    def test_allocations_returns_paged_shape(self):
        app_module = self._load_app_module()
        client = app_module.create_app().test_client()

        response = client.get("/allocations?limit=1")
        self.assertEqual(response.status_code, 200)
        self.assertIn("items", response.json)
        self.assertEqual(response.json["count"], 1)
        self.assertEqual(response.json["limit"], 1)

    def test_auth_gate_rejects_missing_token(self):
        app_module = self._load_app_module(auth_token="secret-token")
        client = app_module.create_app().test_client()

        response = client.get("/health")
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json["error"]["code"], "UNAUTHORIZED")


if __name__ == "__main__":
    unittest.main()
