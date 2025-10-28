from __future__ import annotations

from datetime import timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from sankofa_backend.apps.savings.models import SavingsContribution, SavingsGoal, SavingsRedemption
from sankofa_backend.apps.transactions.models import Transaction, Wallet

User = get_user_model()


class SavingsGoalAPITests(APITestCase):
    def setUp(self) -> None:
        self.user = User.objects.create_user(phone_number="0243333333", full_name="Goal Owner")
        self.client.force_authenticate(self.user)
        self.wallet = Wallet.objects.ensure_for_user(self.user)
        self.wallet.balance = Decimal("5000.00")
        self.wallet.save(update_fields=["balance", "updated_at"])
        self.platform_wallet = Wallet.objects.ensure_platform()
        self.platform_wallet.balance = Decimal("25000.00")
        self.platform_wallet.save(update_fields=["balance", "updated_at"])

    def _create_goal(self, **overrides) -> SavingsGoal:
        now = timezone.now()
        defaults = {
            "user": self.user,
            "title": "Market Expansion",
            "target_amount": Decimal("2000.00"),
            "current_amount": Decimal("500.00"),
            "deadline": now + timedelta(days=60),
            "category": "Business",
        }
        defaults.update(overrides)
        return SavingsGoal.objects.create(**defaults)

    def test_list_returns_user_goals(self):
        goal = self._create_goal()
        other_user = User.objects.create_user(phone_number="0244444444", full_name="Other")
        SavingsGoal.objects.create(
            user=other_user,
            title="Not Mine",
            target_amount=Decimal("1000.00"),
            current_amount=Decimal("100.00"),
            deadline=timezone.now() + timedelta(days=10),
            category="Travel",
        )

        url = reverse("savings:goal-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        payload = response.json()
        self.assertEqual(len(payload), 1)
        self.assertEqual(payload[0]["id"], str(goal.id))
        self.assertEqual(payload[0]["currentAmount"], 500.0)

    def test_create_goal_sets_owner(self):
        url = reverse("savings:goal-list")
        deadline = (timezone.now() + timedelta(days=120)).isoformat()
        response = self.client.post(
            url,
            {
                "title": "New Equipment",
                "targetAmount": "3500.00",
                "deadline": deadline,
                "category": "Operations",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        data = response.json()
        self.assertEqual(data["title"], "New Equipment")
        self.assertEqual(data["currentAmount"], 0.0)
        self.assertEqual(data["userId"], str(self.user.id))
        goal = SavingsGoal.objects.get(id=data["id"])
        self.assertEqual(goal.user, self.user)

    def test_contributions_endpoint_records_payment_and_unlocks_milestones(self):
        goal = self._create_goal(target_amount=Decimal("1000.00"), current_amount=Decimal("200.00"))
        url = reverse("savings:goal-contributions", kwargs={"pk": goal.pk})
        response = self.client.post(
            url,
            {"amount": "300.00", "channel": "Mobile Money", "note": "Weekly boost"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        payload = response.json()
        self.assertEqual(payload["goal"]["currentAmount"], 500.0)
        milestones = payload["unlockedMilestones"]
        self.assertEqual(len(milestones), 2)
        thresholds = sorted(milestone["threshold"] for milestone in milestones)
        self.assertEqual(thresholds, [0.25, 0.5])
        self.assertEqual(Decimal(str(payload["wallet"]["balance"])), Decimal("4700.00"))
        self.assertEqual(Decimal(str(payload["platformWallet"]["balance"])), Decimal("25300.00"))
        self.assertEqual(payload["transaction"]["type"], Transaction.TYPE_SAVINGS)
        self.assertEqual(payload["transaction"]["savingsGoalId"], str(goal.id))

        goal.refresh_from_db()
        self.assertEqual(goal.current_amount, Decimal("500.00"))
        self.assertTrue(
            SavingsContribution.objects.filter(goal=goal, user=self.user, amount=Decimal("300.00")).exists()
        )
        self.wallet.refresh_from_db()
        self.platform_wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal("4700.00"))
        self.assertEqual(self.platform_wallet.balance, Decimal("25300.00"))

    def test_contribution_fails_when_wallet_balance_insufficient(self):
        goal = self._create_goal(target_amount=Decimal("1000.00"), current_amount=Decimal("200.00"))
        self.wallet.balance = Decimal("50.00")
        self.wallet.save(update_fields=["balance", "updated_at"])

        url = reverse("savings:goal-contributions", kwargs={"pk": goal.pk})
        response = self.client.post(url, {"amount": "300.00"}, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("amount", response.json())
        goal.refresh_from_db()
        self.assertEqual(goal.current_amount, Decimal("200.00"))

    def test_contributions_list_returns_only_user_entries(self):
        goal = self._create_goal()
        SavingsContribution.objects.create(
            goal=goal,
            user=self.user,
            amount=Decimal("150.00"),
            channel="Bank", note="Deposit",
        )
        other_user = User.objects.create_user(phone_number="0245555555", full_name="Friend")
        SavingsContribution.objects.create(
            goal=goal,
            user=other_user,
            amount=Decimal("75.00"),
            channel="Cash",
            note="Gift",
        )

        url = reverse("savings:goal-contributions", kwargs={"pk": goal.pk})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(len(data), 1)
        self.assertEqual(Decimal(str(data[0]["amount"])), Decimal("150.00"))

    def test_collect_endpoint_returns_funds_to_wallet(self):
        goal = self._create_goal(current_amount=Decimal("800.00"))

        url = reverse("savings:goal-collect", kwargs={"pk": goal.pk})
        response = self.client.post(
            url,
            {"amount": "300.00", "channel": "Mobile Money", "note": "Reinvest"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        payload = response.json()
        self.assertEqual(payload["goal"]["currentAmount"], 500.0)
        self.assertEqual(payload["transaction"]["type"], Transaction.TYPE_PAYOUT)
        self.assertEqual(payload["transaction"]["savingsGoalId"], str(goal.id))
        self.assertEqual(Decimal(str(payload["wallet"]["balance"])), Decimal("5300.00"))
        self.assertEqual(Decimal(str(payload["platformWallet"]["balance"])), Decimal("24700.00"))

        goal.refresh_from_db()
        self.assertEqual(goal.current_amount, Decimal("500.00"))
        self.assertTrue(
            SavingsRedemption.objects.filter(goal=goal, user=self.user, amount=Decimal("300.00")).exists()
        )
        self.wallet.refresh_from_db()
        self.platform_wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal("5300.00"))
        self.assertEqual(self.platform_wallet.balance, Decimal("24700.00"))

    def test_collect_endpoint_blocks_amount_above_balance(self):
        goal = self._create_goal(current_amount=Decimal("150.00"))

        url = reverse("savings:goal-collect", kwargs={"pk": goal.pk})
        response = self.client.post(url, {"amount": "200.00"}, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        payload = response.json()
        self.assertIn("amount", payload)
        goal.refresh_from_db()
        self.assertEqual(goal.current_amount, Decimal("150.00"))
