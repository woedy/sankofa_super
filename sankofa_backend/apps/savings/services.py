from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import List

from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import transaction
from django.utils import timezone

from .models import SavingsContribution, SavingsGoal, SavingsRedemption
from sankofa_backend.apps.transactions.models import Transaction, Wallet
from sankofa_backend.apps.transactions.services import apply_savings_contribution, apply_savings_payout


MILESTONE_THRESHOLDS: tuple[Decimal, ...] = (Decimal("0.25"), Decimal("0.5"), Decimal("0.75"))


@dataclass(slots=True)
class SavingsMilestone:
    threshold: float
    achieved_at: datetime
    message: str


def record_contribution(
    *,
    goal: SavingsGoal,
    user,
    amount: Decimal,
    channel: str,
    note: str,
) -> tuple[
    SavingsGoal,
    SavingsContribution,
    List[SavingsMilestone],
    Transaction,
    Wallet,
    Wallet,
]:
    with transaction.atomic():
        locked_goal = SavingsGoal.objects.select_for_update().get(pk=goal.pk)
        previous_progress = locked_goal.progress

        transaction_record, user_wallet, platform_wallet = apply_savings_contribution(
            user=user,
            goal=locked_goal,
            amount=amount,
            channel=channel,
            description=f"Savings contribution to {locked_goal.title}",
            note=note,
        )

        locked_goal.current_amount = locked_goal.current_amount + amount
        locked_goal.updated_at = timezone.now()
        locked_goal.save(update_fields=["current_amount", "updated_at"])
        locked_goal.refresh_from_db()

        contribution = SavingsContribution.objects.create(
            goal=locked_goal,
            user=user,
            amount=amount,
            channel=channel,
            note=note,
            recorded_at=timezone.now(),
        )

    milestones = _calculate_milestones(
        goal=locked_goal,
        previous_progress=previous_progress,
        achieved_at=contribution.recorded_at,
    )
    return locked_goal, contribution, milestones, transaction_record, user_wallet, platform_wallet


def collect_savings(
    *,
    goal: SavingsGoal,
    user,
    amount: Decimal,
    channel: str,
    note: str,
) -> tuple[SavingsGoal, SavingsRedemption, Transaction, Wallet, Wallet]:
    with transaction.atomic():
        locked_goal = SavingsGoal.objects.select_for_update().get(pk=goal.pk)

        if amount > locked_goal.current_amount:
            raise DjangoValidationError({"amount": "Cannot collect more than the saved balance."})

        transaction_record, user_wallet, platform_wallet = apply_savings_payout(
            user=user,
            goal=locked_goal,
            amount=amount,
            channel=channel,
            description=f"Savings payout from {locked_goal.title}",
            note=note,
        )

        locked_goal.current_amount = locked_goal.current_amount - amount
        locked_goal.updated_at = timezone.now()
        locked_goal.save(update_fields=["current_amount", "updated_at"])
        locked_goal.refresh_from_db()

        redemption = SavingsRedemption.objects.create(
            goal=locked_goal,
            user=user,
            amount=amount,
            channel=channel,
            note=note,
            recorded_at=timezone.now(),
        )

    return locked_goal, redemption, transaction_record, user_wallet, platform_wallet


def _calculate_milestones(*, goal: SavingsGoal, previous_progress: float, achieved_at: datetime) -> List[SavingsMilestone]:
    current_progress = goal.progress
    unlocked: list[SavingsMilestone] = []

    for threshold in MILESTONE_THRESHOLDS:
        threshold_float = float(threshold)
        if previous_progress < threshold_float <= current_progress:
            message = _build_milestone_message(goal, threshold_float)
            unlocked.append(SavingsMilestone(threshold=threshold_float, achieved_at=achieved_at, message=message))

    return unlocked


def _build_milestone_message(goal: SavingsGoal, threshold: float) -> str:
    percent_label = int(threshold * 100)
    saved_amount = float(goal.target_amount) * threshold
    return f"You unlocked the {percent_label}% milestone for {goal.title}. ₵{saved_amount:,.2f} saved so far!"
