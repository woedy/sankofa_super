from __future__ import annotations

from django.db import migrations

ARTICLES = [
    {
        "slug": "faq-contribution-missing-payment",
        "category": "Wallet & Cashflow",
        "title": "Reconcile a missing contribution payment",
        "summary": "Checklist for verifying MoMo receipts, wallet ledgers, and rotation schedules when a contribution fails to post.",
        "link": "https://support.sankofa/disputes/missing-contribution",
        "tags": ["MoMo", "Ledger Review", "Receipts"],
    },
    {
        "slug": "faq-payout-delay",
        "category": "Wallet & Cashflow",
        "title": "Resolve delayed susu payouts",
        "summary": "Troubleshooting guide covering treasury windows, compliance gates, and notifying members during payout delays.",
        "link": "https://support.sankofa/disputes/payout-delay",
        "tags": ["Payout", "Compliance", "Treasury"],
    },
    {
        "slug": "faq-account-adjustment",
        "category": "Account & KYC",
        "title": "Undo duplicate wallet deductions",
        "summary": "Steps to issue manual credits, annotate accounts, and confirm with members when double charges occur.",
        "link": "https://support.sankofa/disputes/account-adjustment",
        "tags": ["Adjustments", "Wallet"],
    },
    {
        "slug": "faq-withdrawal-compliance",
        "category": "Compliance & Risk",
        "title": "Clear withdrawals stuck in compliance review",
        "summary": "Enhanced due diligence workflow for high-risk withdrawals, including ID checks and escalation paths.",
        "link": "https://support.sankofa/disputes/withdrawal-compliance",
        "tags": ["EDD", "Risk Flags", "KYC"],
    },
    {
        "slug": "faq-group-invite",
        "category": "Susu Groups",
        "title": "Improve invite acceptance for susu groups",
        "summary": "Outreach templates, reminder cadence, and manual override options for stalled group invitations.",
        "link": "https://support.sankofa/disputes/group-invite",
        "tags": ["Invites", "Engagement", "Reminders"],
    },
    {
        "slug": "faq-notifications-escalation",
        "category": "Notifications & Alerts",
        "title": "Configure escalation alerts for disputes",
        "summary": "Map severity tiers to the correct notification channels and ensure escalations reach on-call owners.",
        "link": "https://support.sankofa/disputes/notifications-escalation",
        "tags": ["Alerts", "Routing"],
    },
]


def create_articles(apps, schema_editor):
    Article = apps.get_model("disputes", "SupportArticle")
    for data in ARTICLES:
        Article.objects.update_or_create(slug=data["slug"], defaults=data)


def remove_articles(apps, schema_editor):
    Article = apps.get_model("disputes", "SupportArticle")
    Article.objects.filter(slug__in=[article["slug"] for article in ARTICLES]).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("disputes", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(create_articles, remove_articles),
    ]
