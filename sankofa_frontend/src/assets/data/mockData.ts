export const memberProfile = {
  name: 'Ama Boateng',
  phone: '+233 50 123 4567',
  avatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80',
  kycStatus: 'Verified',
  tier: 'Growth Member',
  walletBalance: 5280.75,
  savingsTotal: 18650,
  notificationCount: 3,
  preferences: {
    language: 'English',
    theme: 'light',
    biometrics: true,
    marketing: false
  }
};

export const onboardingSlides = [
  {
    title: 'Build wealth together',
    description: 'Join trusted susu groups with instant transparency, flexible payouts, and community safeguards.',
    image: 'https://images.unsplash.com/photo-1545239351-1141bd82e8a6?auto=format&fit=crop&w=900&q=80'
  },
  {
    title: 'Boost your savings goals',
    description: 'Automated reminders, mobile money deposits, and celebration milestones keep you motivated.',
    image: 'https://images.unsplash.com/photo-1545239351-1141bd82e8a6?auto=format&fit=crop&w=900&q=80'
  },
  {
    title: 'Stay in control 24/7',
    description: 'Track contributions, payouts, and receipts in real-time across devices with Sankofa.',
    image: 'https://images.unsplash.com/photo-1483478550801-ceba5fe50e8e?auto=format&fit=crop&w=900&q=80'
  }
];

export const groups = [
  {
    id: 'grp-01',
    name: 'Accra Market Women',
    cycleStatus: 'Active',
    members: 12,
    nextPayout: 'Nov 28, 2025',
    contribution: 500,
    totalPool: 24000,
    heroImage: 'https://images.unsplash.com/photo-1509099836639-18ba1795216d?auto=format&fit=crop&w=900&q=80'
  },
  {
    id: 'grp-02',
    name: 'Tema Nurses Circle',
    cycleStatus: 'Onboarding',
    members: 9,
    nextPayout: 'Dec 12, 2025',
    contribution: 400,
    totalPool: 14400,
    heroImage: 'https://images.unsplash.com/photo-1530023367847-a683933f4177?auto=format&fit=crop&w=900&q=80'
  }
];

export const savingsGoals = [
  {
    id: 'goal-01',
    name: 'Emergency Cushion',
    category: 'Safety',
    targetAmount: 10000,
    savedAmount: 6500,
    targetDate: 'Mar 2026'
  },
  {
    id: 'goal-02',
    name: 'Shop Renovation',
    category: 'Business',
    targetAmount: 15000,
    savedAmount: 9800,
    targetDate: 'Jul 2026'
  }
];

export const transactions = [
  {
    id: 'TXN-548921',
    type: 'Deposit',
    amount: 1200,
    status: 'Completed',
    date: 'Nov 03, 2025',
    channel: 'Mobile Money',
    reference: 'MOMO-8392'
  },
  {
    id: 'TXN-548822',
    type: 'Contribution',
    amount: 500,
    status: 'Completed',
    date: 'Oct 29, 2025',
    channel: 'Group Draft',
    reference: 'GROUP-2045'
  },
  {
    id: 'TXN-548731',
    type: 'Withdrawal',
    amount: 800,
    status: 'Pending',
    date: 'Oct 22, 2025',
    channel: 'Mobile Money',
    reference: 'MOMO-7234'
  }
];

export const notifications = [
  {
    id: 'noti-01',
    title: 'Payout scheduled',
    body: 'Your Accra Market Women payout is scheduled for Nov 28. Review the checklist to confirm your details.',
    time: '2h ago',
    read: false
  },
  {
    id: 'noti-02',
    title: 'Contribution received',
    body: 'GH₵500 contribution posted for Tema Nurses Circle cycle 2.',
    time: '1d ago',
    read: false
  },
  {
    id: 'noti-03',
    title: 'Savings milestone unlocked',
    body: 'You are 65% of the way to Emergency Cushion. Keep going!',
    time: '3d ago',
    read: true
  }
];

export const supportArticles = [
  {
    id: 'article-01',
    category: 'Getting Started',
    question: 'How do I verify my identity?',
    answer: 'Upload a valid Ghana Card or passport, confirm your details, and our compliance team will review within 24 hours.'
  },
  {
    id: 'article-02',
    category: 'Groups',
    question: 'How are payouts determined?',
    answer: 'Payout sequence follows the group roster. View your spot in the group detail page and request swaps if needed.'
  },
  {
    id: 'article-03',
    category: 'Wallet',
    question: 'Which channels do you support?',
    answer: 'We support all major mobile money networks in Ghana and direct bank transfers to select banks.'
  }
];

export const processFlows = [
  {
    id: 'flow-deposit',
    name: 'Deposit funds',
    steps: ['Enter amount', 'Pick mobile money account', 'Confirm fees', 'Receive receipt'],
    description: 'Top up your Sankofa wallet instantly using MTN, AirtelTigo, or Vodafone cash.'
  },
  {
    id: 'flow-withdrawal',
    name: 'Request withdrawal',
    steps: ['Enter amount', 'Complete compliance checklist', 'Select channel', 'Track status'],
    description: 'Send funds back to your wallet or mobile money account with transparent fees.'
  }
];
