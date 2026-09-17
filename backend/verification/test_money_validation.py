import unittest

from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from pydantic import ValidationError

from app.core.errors import install_error_handling
from app.modules.fees.schemas import PaymentCreate, InvoiceCreate, BulkInvoiceCreate, FeeStructureCreate


class MoneyValidationTest(unittest.IsolatedAsyncioTestCase):
    async def test_non_finite_json_returns_safe_validation_error(self):
        app = FastAPI()
        install_error_handling(app)

        @app.post("/payment")
        async def payment(data: PaymentCreate):
            return {"amount": data.amount}

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/payment", content=(
                '{"amount":1e999,"method":"cash","paid_on":"2026-09-14","note":"private-note"}'
            ), headers={"Content-Type": "application/json"})
        self.assertEqual(response.status_code, 422)
        self.assertNotIn("private-note", response.text)
        self.assertNotIn('"input"', response.text)
        self.assertEqual(response.json()["detail"][0]["loc"], ["body", "amount"])

    def test_all_fee_write_schemas_reject_non_finite_amounts(self):
        for schema in (PaymentCreate, InvoiceCreate, BulkInvoiceCreate, FeeStructureCreate):
            for amount in (float("inf"), float("-inf"), float("nan")):
                with self.subTest(schema=schema.__name__, amount=amount):
                    with self.assertRaises(ValidationError) as ctx:
                        schema.model_validate({"amount": amount})
                    self.assertTrue(any(e["loc"] == ("amount",) for e in ctx.exception.errors()))
