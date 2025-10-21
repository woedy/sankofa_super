import 'package:flutter/material.dart';
import 'package:sankofasave/models/process_flow_model.dart';

class ProcessFlows {
  static final ProcessFlowModel deposit = ProcessFlowModel(
    id: 'deposit',
    title: 'Deposit Funds',
    subtitle: 'Follow your MoMo top-up journey end-to-end.',
    heroAsset: 'assets/images/Digital_mobile_money_wallet_null_1760947750116.png',
    expectation: 'Under 1 min • MTN/Vodafone/AirtelTigo • BoG regulated',
    steps: const [
      ProcessStepModel(
        title: 'Initiate Mobile Money Deposit',
        description: 'Choose Mobile Money, enter the amount you want to add, and confirm your registered MoMo number.',
        icon: Icons.smartphone_outlined,
        helper: 'We auto-detect the +233 code and validate that your Ghana Card number matches the SIM.',
        badge: 'Step 1',
      ),
      ProcessStepModel(
        title: 'Approve with PIN',
        description: 'A MoMo prompt pops up instantly so you can review fees and authorise with your MoMo PIN.',
        icon: Icons.verified_user_outlined,
        helper: 'No SMS typing required—just approve the secure STK push.',
        badge: 'Step 2',
      ),
      ProcessStepModel(
        title: 'Wallet Updated',
        description: 'Your Sankofa wallet balance refreshes in real time with a receipt and transaction timeline entry.',
        icon: Icons.account_balance_wallet_outlined,
        helper: 'Receipts include the Bank of Ghana reference, fee split, and a downloadable PDF copy.',
        badge: 'Step 3',
      ),
    ],
    highlights: const [
      'Your cedi wallet ledger reconciles with our licensed float instantly.',
      'Digital receipts are emailed to you and any linked group admins automatically.',
      'Anti-fraud checks confirm SIM registration and KYC status before funds clear.',
    ],
    completionTitle: 'Deposit Completed',
    completionDescription: 'You see your wallet balance refresh instantly, ready to move funds into a Susu cycle or personal goal.',
    primaryActionLabel: 'Preview Receipt',
    secondaryActionLabel: 'Share Confirmation',
  );

  static final ProcessFlowModel withdrawal = ProcessFlowModel(
    id: 'withdrawal',
    title: 'Withdraw to Mobile Money',
    subtitle: 'See how members cash out to mobile money instantly.',
    heroAsset: 'assets/images/Ghana_flag_colors_null_1760947804962.png',
    expectation: '≈2 min • Instant push • Auto limits applied',
    steps: const [
      ProcessStepModel(
        title: 'Choose Amount & Channel',
        description: 'Select how much you want to cash out, pick your preferred MoMo wallet, and review any daily limit reminders.',
        icon: Icons.savings_outlined,
        helper: 'See your available balance, pending holds, and the minimum float required before submitting.',
        badge: 'Step 1',
      ),
      ProcessStepModel(
        title: 'Compliance Safety Check',
        description: 'We automatically check your KYC status, AML flags, and confirm there are no outstanding group arrears.',
        icon: Icons.shield_moon_outlined,
        helper: 'You get a clear checklist so you know the safeguards protecting your payouts.',
        badge: 'Step 2',
      ),
      ProcessStepModel(
        title: 'Cash Arrives on Phone',
        description: 'Your MoMo credit alert lands instantly, and the withdrawal timeline logs a payout reference plus support link.',
        icon: Icons.payments_outlined,
        helper: 'Download the proof-of-payout PDF or share it via WhatsApp in one tap.',
        badge: 'Step 3',
      ),
    ],
    highlights: const [
      'Network fees and Sankofa commission are calculated automatically and shown upfront.',
      'Schedule partial withdrawals, lock escrow funds, or set future payouts confidently.',
      'Every payout includes a full audit trail with GPS location and device fingerprint.',
    ],
    completionTitle: 'Withdrawal Confirmed',
    completionDescription: 'You receive your funds instantly and see your wallet balance update with a new ledger entry.',
    primaryActionLabel: 'View Audit Trail',
    secondaryActionLabel: 'Download Receipt',
  );

  static final ProcessFlowModel joinGroup = ProcessFlowModel(
    id: 'join-group',
    title: 'Join a Susu Group',
    subtitle: 'Explore public Susu circles you can join with confidence.',
    heroAsset: 'assets/images/African_community_savings_group_null_1760947730962.png',
    expectation: 'Smart matches • Live vetting • Trust signals',
    steps: const [
      ProcessStepModel(
        title: 'Discover Curated Groups',
        description: 'Filter public groups by contribution size, cycle length, and sector to find the perfect fit.',
        icon: Icons.group_outlined,
        helper: 'Badges highlight verified admins, success rates, and recovery history so you can choose confidently.',
        badge: 'Step 1',
      ),
      ProcessStepModel(
        title: 'Submit Smart Application',
        description: 'Review the group rules, complete a quick KYC refresh, and share your purpose statement by voice or text.',
        icon: Icons.assignment_turned_in_outlined,
        helper: 'We suggest references from members you already know to boost acceptance odds.',
        badge: 'Step 2',
      ),
      ProcessStepModel(
        title: 'Get Approved & Onboarded',
        description: 'Once admins approve you, your payout position, contribution schedule, and start date appear instantly.',
        icon: Icons.celebration_outlined,
        helper: 'The welcome checklist nudges you to set auto-contributions and invite an accountability partner.',
        badge: 'Step 3',
      ),
    ],
    highlights: const [
      'Group health scores update in real time using repayment data and attendance logs.',
      'You accept the NDA and constitution with a secure digital signature.',
      'Stay engaged with group chat, voice drops, and scheduled reminders.',
    ],
    completionTitle: 'Membership Activated',
    completionDescription: 'You join the Unity Savers Group with contribution reminders, a payout calendar, and community access.',
    primaryActionLabel: 'View Welcome Kit',
    secondaryActionLabel: 'Invite Accountability Partner',
  );

  static final ProcessFlowModel createGroup = ProcessFlowModel(
    id: 'create-group',
    title: 'Create a Private Group',
    subtitle: 'Set up an invite-only Susu circle for trusted members.',
    heroAsset: 'assets/images/African_woman_professional_null_1760947773326.jpg',
    expectation: '≈3 min setup • Private invites • Secure controls',
    steps: const [
      ProcessStepModel(
        title: 'Define Your Group Blueprint',
        description: 'Name the circle, choose the contribution amount, and set how long each cycle should run.',
        icon: Icons.dashboard_customize_outlined,
        helper: 'Live previews show how the payout calendar adjusts as you tweak amounts and duration.',
        badge: 'Step 1',
      ),
      ProcessStepModel(
        title: 'Configure Contribution Rules',
        description: 'Pick the payout order, add safety buffers, and decide when reminders should be sent.',
        icon: Icons.rule_folder_outlined,
        helper: 'We surface best-practice presets so you can launch quickly and refine later.',
        badge: 'Step 2',
      ),
      ProcessStepModel(
        title: 'Invite Your Inner Circle',
        description: 'Send private links or add members manually, then track who has accepted and completed KYC.',
        icon: Icons.mail_lock_outlined,
        helper: 'Invite dashboard shows real-time status, pending actions, and suggested accountability partners.',
        badge: 'Step 3',
      ),
    ],
    highlights: const [
      'Launch-ready templates help you spin up investment, family, or community-focused circles.',
      'Access controls limit visibility to invited members while keeping admins in full control.',
      'Automated onboarding nudges keep everyone on track before the first contribution date.',
    ],
    completionTitle: 'Private Group Ready',
    completionDescription: 'Your invite-only circle is live with onboarding checklists and a shareable invite link.',
    primaryActionLabel: 'Share Invite Link',
    secondaryActionLabel: 'Preview Onboarding Checklist',
  );

  static final ProcessFlowModel savings = ProcessFlowModel(
    id: 'savings',
    title: 'Automated Savings Plan',
    subtitle: 'Watch how automated savings goals get set up and tracked.',
    heroAsset: 'assets/images/Financial_goal_achievement_null_1760947760860.png',
    expectation: 'Flexible cadence • Partner interest • Insured pool',
    steps: const [
      ProcessStepModel(
        title: 'Define the Goal',
        description: 'Name your goal, set the target amount, and choose the timeline that works for you.',
        icon: Icons.flag_outlined,
        helper: 'The projection widget calculates the recommended weekly contribution automatically.',
        badge: 'Step 1',
      ),
      ProcessStepModel(
        title: 'Automate Funding',
        description: 'Link your wallet or group payouts and schedule automatic top-ups that suit your rhythm.',
        icon: Icons.autorenew,
        helper: 'Smart autopay pauses during cycle payout weeks so your cashflow stays steady.',
        badge: 'Step 2',
      ),
      ProcessStepModel(
        title: 'Track Milestones',
        description: 'Celebrate 25%, 50%, and 75% milestones with shareable badges and progress insights.',
        icon: Icons.insights_outlined,
        helper: 'A detailed breakdown shows interest earned, bonuses, and upcoming deposits.',
        badge: 'Step 3',
      ),
    ],
    highlights: const [
      'AI nudges suggest top-ups after big payouts or when you fall behind.',
      'Savings are safeguarded with our licensed microfinance partner and insured pool.',
      'Need flexibility? Enjoy three penalty-free emergency withdrawals each year.',
    ],
    completionTitle: 'Goal on Track',
    completionDescription: 'Your dashboard celebrates the streak and even projects when you will finish ahead of schedule.',
    primaryActionLabel: 'See Goal Timeline',
    secondaryActionLabel: 'Share Progress',
  );

  static ProcessFlowModel byId(String id) {
    switch (id) {
      case 'deposit':
        return deposit;
      case 'withdrawal':
        return withdrawal;
      case 'join-group':
        return joinGroup;
      case 'create-group':
        return createGroup;
      case 'savings':
        return savings;
      default:
        return deposit;
    }
  }
}