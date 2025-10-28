from __future__ import annotations

from datetime import timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from sankofa_backend.apps.transactions.models import Transaction, Wallet

User = get_user_model()


class TransactionAPITests(APITestCase):
    def setUp(self) -> None:
        self.user = User.objects.create_user(phone_number="0240000000", full_name="Tester")
        self.client.force_authenticate(self.user)
        Wallet.objects.ensure_platform()

    def _create_transaction(
        self,
        *,
        user,
        transaction_type: str,
        status: str = Transaction.STATUS_SUCCESS,
        amount: Decimal | str = "100.00",
        description: str = "Test transaction",
        occurred_at=None,
        channel: str = "Mobile Money",
        reference: str = "REF-1",
        counterparty: str = "Counterparty",
    ) -> Transaction:
        occurred_at = occurred_at or timezone.now()
        return Transaction.objects.create(
            user=user,
            transaction_type=transaction_type,
            status=status,
            amount=Decimal(amount),
            description=description,
            occurred_at=occurred_at,
            channel=channel,
            reference=reference,
            counterparty=counterparty,
        )

    def test_list_returns_only_authenticated_user_transactions(self):
        older = self._create_transaction(
            user=self.user,
            transaction_type=Transaction.TYPE_DEPOSIT,
            amount="250.00",
            occurred_at=timezone.now() - timedelta(days=2),
            description="Wallet top up",
            reference="DEP-1",
        )
        newer = self._create_transaction(
            user=self.user,
            transaction_type=Transaction.TYPE_WITHDRAWAL,
            amount="150.50",
            status=Transaction.STATUS_PENDING,
            occurred_at=timezone.now() - timedelta(hours=2),
            description="Wallet withdrawal",
            reference="WDR-1",
        )
        self._create_transaction(
            user=User.objects.create_user(phone_number="0241111111", full_name="Other"),
            transaction_type=Transaction.TYPE_DEPOSIT,
            description="Foreign entry",
        )

        url = reverse("transactions:transaction-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        payload = response.json()
        self.assertEqual(payload["count"], 2)
        self.assertEqual(len(payload["results"]), 2)

        first = payload["results"][0]
        self.assertEqual(first["id"], str(newer.id))
        self.assertEqual(first["type"], Transaction.TYPE_WITHDRAWAL)
        self.assertEqual(first["status"], Transaction.STATUS_PENDING)
        self.assertAlmostEqual(float(first["amount"]), float(newer.amount))
        self.assertEqual(first["reference"], "WDR-1")

        second = payload["results"][1]
        self.assertEqual(second["id"], str(older.id))
        self.assertEqual(second["type"], Transaction.TYPE_DEPOSIT)

    def test_filters_apply_type_status_and_date_range(self):
        anchor = timezone.now()
        matching = self._create_transaction(
            user=self.user,
            transaction_type=Transaction.TYPE_DEPOSIT,
            status=Transaction.STATUS_SUCCESS,
            occurred_at=anchor - timedelta(days=1),
            description="Deposit in range",
        )
        self._create_transaction(
            user=self.user,
            transaction_type=Transaction.TYPE_WITHDRAWAL,
            status=Transaction.STATUS_FAILED,
            occurred_at=anchor - timedelta(days=3),
            description="Outside filters",
        )

        url = reverse("transactions:transaction-list")
        params = {
            "types": "deposit",
            "statuses": "success",
            "start": (anchor - timedelta(days=2)).isoformat(),
            "end": (anchor - timedelta(hours=12)).isoformat(),
        }
        response = self.client.get(url, params)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        payload = response.json()
        self.assertEqual(payload["count"], 1)
        self.assertEqual(payload["results"][0]["id"], str(matching.id))

    def test_summary_returns_totals(self):
        anchor = timezone.now()
        self._create_transaction(
            user=self.user,
            transaction_type=Transaction.TYPE_DEPOSIT,
            status=Transaction.STATUS_SUCCESS,
            amount="500.00",
            occurred_at=anchor - timedelta(days=1),
        )
        self._create_transaction(
            user=self.user,
            transaction_type=Transaction.TYPE_PAYOUT,
            status=Transaction.STATUS_SUCCESS,
            amount="300.00",
            occurred_at=anchor - timedelta(days=2),
        )
        self._create_transaction(
            user=self.user,
            transaction_type=Transaction.TYPE_WITHDRAWAL,
            status=Transaction.STATUS_PENDING,
            amount="200.00",
            occurred_at=anchor - timedelta(hours=3),
        )

        url = reverse("transactions:transaction-summary")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        payload = response.json()

        self.assertEqual(payload["totalCount"], 3)
        self.assertEqual(payload["pendingCount"], 1)
        self.assertEqual(payload["totalsByType"][0]["type"], Transaction.TYPE_DEPOSIT)
        self.assertEqual(payload["totalsByType"][0]["count"], 1)
        self.assertEqual(payload["totalsByStatus"][0]["status"], Transaction.STATUS_SUCCESS)
        self.assertAlmostEqual(float(payload["totalInflow"]), 800.0)
        self.assertAlmostEqual(float(payload["totalOutflow"]), 200.0)
        self.assertAlmostEqual(float(payload["netCashflow"]), 600.0)

    def test_deposit_endpoint_updates_wallets(self):
        url = reverse("transactions:transaction-deposit")
        response = self.client.post(
            url,
            {
                "amount": "150.00",
                "channel": "MTN MoMo",
                "reference": "DEP-001",
                "counterparty": "+233241234567",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        payload = response.json()
        self.assertEqual(payload["transaction"]["type"], Transaction.TYPE_DEPOSIT)

        user_wallet = Wallet.objects.get(user=self.user)
        platform_wallet = Wallet.objects.get(is_platform=True)
        self.assertEqual(user_wallet.balance, Decimal("150.00"))
        self.assertEqual(platform_wallet.balance, Decimal("150.00"))

    def test_withdraw_endpoint_respects_balance_and_status(self):
        Wallet.objects.ensure_for_user(self.user)
        apply_deposit_url = reverse("transactions:transaction-deposit")
        self.client.post(apply_deposit_url, {"amount": "300.00"}, format="json")

        url = reverse("transactions:transaction-withdraw")
        response = self.client.post(
            url,
            {
                "amount": "120.00",
                "status": Transaction.STATUS_SUCCESS,
                "channel": "MTN MoMo",
                "reference": "WDR-001",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        payload = response.json()
        self.assertEqual(payload["transaction"]["status"], Transaction.STATUS_SUCCESS)

        user_wallet = Wallet.objects.get(user=self.user)
        platform_wallet = Wallet.objects.get(is_platform=True)
        self.assertEqual(user_wallet.balance, Decimal("180.00"))
        self.assertEqual(platform_wallet.balance, Decimal("180.00"))

        insufficient = self.client.post(
            url,
            {"amount": "500.00", "status": Transaction.STATUS_SUCCESS},
            format="json",
        )
        self.assertEqual(insufficient.status_code, status.HTTP_400_BAD_REQUEST)

    def test_deposit_accepts_high_precision_fee_values(self):
        url = reverse("transactions:transaction-deposit")
        payload = {
            "amount": 100.0,
            "fee": 1.2000000000000002,
            "channel": "MTN MoMo",
        }

        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        transaction = Transaction.objects.get(transaction_type=Transaction.TYPE_DEPOSIT)
        self.assertEqual(transaction.fee, Decimal("1.20"))

    def test_withdraw_accepts_destination_and_note(self):
        Wallet.objects.ensure_for_user(self.user)
        deposit_url = reverse("transactions:transaction-deposit")
        self.client.post(deposit_url, {"amount": "250.00"}, format="json")

        url = reverse("transactions:transaction-withdraw")
        response = self.client.post(
            url,
            {
                "amount": "80.00",
                "status": Transaction.STATUS_SUCCESS,
                "destination": "0244000000",
                "note": "Cash out at Ridge",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        transaction = Transaction.objects.get(transaction_type=Transaction.TYPE_WITHDRAWAL)
        self.assertEqual(transaction.counterparty, "0244000000")
        self.assertIn("Cash out at Ridge", transaction.description)
