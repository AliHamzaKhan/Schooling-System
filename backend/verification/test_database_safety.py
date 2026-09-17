"""Safety checks run independently of the database-backed pytest fixtures."""
import unittest

from app.core.test_database import assert_database_identity, configure_test_environment

URL = "postgresql+asyncpg://schooling_test_runner:secret@localhost/schooling_test_fixture"


class DatabaseSafetyTest(unittest.TestCase):
    def test_normal_database_is_never_a_fallback(self):
        with self.assertRaisesRegex(RuntimeError, "required"):
            configure_test_environment({"DATABASE_URL": "production"})

    def test_rejects_invalid_or_ambiguous_targets_without_exposing_credentials(self):
        for url in ("broken", URL.replace("schooling_test_fixture", "schooling"),
                    URL.replace("schooling_test_runner", "postgres"),
                    URL + "?host=other", URL.replace("postgresql+asyncpg", "sqlite")):
            with self.subTest(url=url), self.assertRaises(RuntimeError) as ctx:
                configure_test_environment({"SCHOOLING_TEST_DATABASE_URL": url})
            self.assertNotIn("secret", str(ctx.exception))

    def test_explicit_target_overrides_inherited_db_components_and_providers(self):
        env = {"SCHOOLING_TEST_DATABASE_URL": URL, "DB_HOST": "production",
               "DB_NAME": "schooling", "DB_USER": "real_user", "DATABASE_URL": "production",
               "TWILIO_AUTH_TOKEN": "live", "TASK_QUEUE_ENABLED": "true"}
        self.assertEqual(configure_test_environment(env), URL)
        self.assertEqual(env["DATABASE_URL"], URL)
        self.assertEqual(env["DB_HOST"], "")
        self.assertEqual(env["TWILIO_AUTH_TOKEN"], "")
        self.assertEqual(env["TASK_QUEUE_ENABLED"], "false")

    def test_connected_target_must_be_empty_owned_and_unprivileged(self):
        valid = dict(database="schooling_test_fixture", username="schooling_test_runner",
                     owner="schooling_test_runner", superuser=False, create_db=False,
                     create_role=False, has_tables=False, expected_url=URL)
        assert_database_identity(**valid)
        for key, value in (("database", "schooling"), ("username", "postgres"),
                           ("owner", "postgres"), ("superuser", True), ("create_db", True),
                           ("create_role", True), ("has_tables", True)):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                assert_database_identity(**(valid | {key: value}))
