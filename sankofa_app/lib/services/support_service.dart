import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sankofasave/models/support_article_model.dart';

class SupportService {
  SupportService._internal();

  static final SupportService _instance = SupportService._internal();

  factory SupportService() => _instance;

  static const String _fallbackJson = '''
[
  {
    "id": "private-group-basics",
    "category": "Susu Groups",
    "title": {"en": "How do I start a private Susu group?"},
    "summary": {
      "en": "Walk through the creation wizard to set your circle's size, cadence, and invites."
    },
    "sections": [
      {
        "heading": {"en": "Launch the wizard"},
        "body": {
          "en": [
            "Open the Groups tab and use the Create Private Group action to launch the four-step setup wizard.",
            "Give your circle a friendly name, define how many members will participate, and select the contribution amount everyone will send each cycle."
          ]
        }
      },
      {
        "heading": {"en": "Set rules & invites"},
        "body": {
          "en": [
            "Choose how long each payout cycle lasts and whether the owner needs to approve contributions before funds are released.",
            "Add trusted contacts as staged members—everyone will receive an invite to review rules and submit KYC details."
          ]
        }
      },
      {
        "heading": {"en": "Finalize your circle"},
        "body": {
          "en": [
            "Review the summary screen to confirm cadence, contribution totals, and invite notes before launching.",
            "Tap Create group to publish your circle; you'll see reminder tools and roster insights on the group detail page."
          ]
        }
      }
    ],
    "tags": ["groups", "setup", "invites"]
  },
  {
    "id": "savings-milestones",
    "category": "Savings Goals",
    "title": {"en": "What happens when I boost a goal?"},
    "summary": {
      "en": "Every top-up updates your progress, unlocks milestone badges, and logs a wallet transaction."
    },
    "sections": [
      {
        "heading": {"en": "Real-time progress"},
        "body": {
          "en": [
            "Boosting a goal instantly recalculates your completion percentage and refreshes the progress bar.",
            "You'll see updated contribution history with timestamps and amounts for each boost."
          ]
        }
      },
      {
        "heading": {"en": "Milestone celebrations"},
        "body": {
          "en": [
            "Hitting 25%, 50%, or 75% triggers milestone badges, celebratory copy, and a notification in your inbox.",
            "Milestones make it easy to recognize momentum and share wins with your Susu circle."
          ]
        }
      },
      {
        "heading": {"en": "Wallet sync"},
        "body": {
          "en": [
            "Each boost posts a matching entry to your Transactions tab so your cashflow stays in sync.",
            "You can tap any boost in the transaction list to view the detailed bottom-sheet receipt."
          ]
        }
      }
    ],
    "tags": ["savings", "milestones", "boosts"]
  },
  {
    "id": "wallet-deposits",
    "category": "Wallet",
    "title": {"en": "How do wallet deposits work?"},
    "summary": {
      "en": "Use the guided deposit flow to top up via mobile money, review fees, and receive a receipt."
    },
    "sections": [
      {
        "heading": {"en": "Choose your amount"},
        "body": {
          "en": [
            "From Home or Transactions, tap Deposit to open the amount screen with quick-fill chips.",
            "Enter a custom figure or tap a suggestion, then continue to pick your preferred channel."
          ]
        }
      },
      {
        "heading": {"en": "Select a channel"},
        "body": {
          "en": [
            "Pick the mobile money provider that matches your wallet.",
            "We summarise estimated fees, settlement time, and reference ID before you confirm."
          ]
        }
      },
      {
        "heading": {"en": "Track the receipt"},
        "body": {
          "en": [
            "After submission you'll see a success sheet with your reference code.",
            "The wallet balance updates immediately and the transaction detail modal lists channel, fee, and timeline metadata."
          ]
        }
      }
    ],
    "tags": ["wallet", "deposits", "receipts"]
  },
  {
    "id": "wallet-withdrawals",
    "category": "Wallet",
    "title": {"en": "What should I know about withdrawals?"},
    "summary": {
      "en": "Our withdrawal wizard captures compliance, destination details, and keeps you updated on status changes."
    },
    "sections": [
      {
        "heading": {"en": "Complete compliance checks"},
        "body": {
          "en": [
            "Before funds move we confirm your ID match and capture your purpose of withdrawal.",
            "You'll acknowledge terms and review how long settlement takes for your destination channel."
          ]
        }
      },
      {
        "heading": {"en": "Monitor status"},
        "body": {
          "en": [
            "Once submitted you'll see a status badge in Transactions—success posts immediately, while holds show as pending.",
            "If a request fails we'll send you a notification with guidance to resubmit or contact support."
          ]
        }
      },
      {
        "heading": {"en": "Know the fees"},
        "body": {
          "en": [
            "The review step outlines any processing fees so there are no surprises.",
            "A detailed receipt stays available in the transaction detail modal for your records."
          ]
        }
      }
    ],
    "tags": ["wallet", "withdrawals", "compliance"]
  },
  {
    "id": "account-security",
    "category": "Security",
    "title": {"en": "How do I keep my account secure?"},
    "summary": {
      "en": "Toggle biometric sign-in, enable alerts, and monitor trusted devices from the Profile hub."
    },
    "sections": [
      {
        "heading": {"en": "Strengthen sign-in"},
        "body": {
          "en": [
            "Create a strong PIN and avoid reusing it across other services.",
            "Review your recovery contacts so we can help if you lose access."
          ]
        }
      },
      {
        "heading": {"en": "Use layered security"},
        "body": {
          "en": [
            "Turn on two-step verification under Profile → Security to confirm new sign-ins.",
            "Enable biometric sign-in for faster but secure access on your trusted devices."
          ]
        }
      },
      {
        "heading": {"en": "Review active sessions"},
        "body": {
          "en": [
            "Check trusted devices regularly and revoke access you no longer recognize.",
            "We'll send you transaction alerts and savings nudges so unusual activity gets your attention right away."
          ]
        }
      }
    ],
    "tags": ["security", "account", "alerts"]
  }
]
''';

  List<SupportArticleModel>? _cache;

  Future<List<SupportArticleModel>> fetchArticles() async {
    if (_cache != null) {
      return _cache!;
    }

    try {
      final String jsonStr = await rootBundle.loadString('assets/data/support_topics.json');
      final articles = SupportArticleModel.listFromJsonString(jsonStr);
      if (articles.isNotEmpty) {
        _cache = articles;
        return _cache!;
      }
    } catch (_) {
      // Fall back to the bundled constant below if the asset lookup fails.
    }

    _cache = SupportArticleModel.listFromJsonString(_fallbackJson);
    return _cache!;
  }

  Future<SupportArticleModel?> fetchArticleById(String id) async {
    final articles = await fetchArticles();
    try {
      return articles.firstWhere((article) => article.id == id);
    } catch (_) {
      return null;
    }
  }
}
