// Mock data for the Sankofa Admin Dashboard enriched to mirror mobile app entities

export const mockUsers = [
  { id: 'user_001', name: 'Kwame Mensah', phone: '+233 24 123 4567', email: 'kwame.mensah@example.com', kycStatus: 'Approved', walletBalance: 2450.32, status: 'Active', joinedDate: '2023-11-02', avatar: 'KM' },
  { id: 'user_002', name: 'Ama Darko', phone: '+233 20 777 4410', email: 'ama.darko@example.com', kycStatus: 'Pending', walletBalance: 1840.75, status: 'Active', joinedDate: '2024-01-08', avatar: 'AD' },
  { id: 'user_003', name: 'Kofi Asante', phone: '+233 55 218 9034', email: 'kofi.asante@example.com', kycStatus: 'Approved', walletBalance: 3680.40, status: 'Active', joinedDate: '2023-09-17', avatar: 'KA' },
  { id: 'user_004', name: 'Abena Osei', phone: '+233 27 110 4582', email: 'abena.osei@example.com', kycStatus: 'Approved', walletBalance: 1295.10, status: 'Active', joinedDate: '2024-02-21', avatar: 'AO' },
  { id: 'user_005', name: 'Yaw Boateng', phone: '+233 24 880 5521', email: 'yaw.boateng@example.com', kycStatus: 'Approved', walletBalance: 950.00, status: 'Suspended', joinedDate: '2023-12-12', avatar: 'YB' },
  { id: 'user_006', name: 'Akua Frimpong', phone: '+233 23 998 1200', email: 'akua.frimpong@example.com', kycStatus: 'Pending', walletBalance: 420.55, status: 'Active', joinedDate: '2024-03-03', avatar: 'AF' },
  { id: 'user_007', name: 'Efua Adjei', phone: '+233 30 660 9033', email: 'efua.adjei@example.com', kycStatus: 'Approved', walletBalance: 2580.90, status: 'Active', joinedDate: '2023-10-26', avatar: 'EA' },
  { id: 'user_008', name: 'Adwoa Mensah', phone: '+233 50 214 7741', email: 'adwoa.mensah@example.com', kycStatus: 'Approved', walletBalance: 740.25, status: 'Active', joinedDate: '2024-04-04', avatar: 'AM' },
  { id: 'user_009', name: 'Kwesi Owusu', phone: '+233 55 502 1109', email: 'kwesi.owusu@example.com', kycStatus: 'Pending', walletBalance: 1140.00, status: 'Active', joinedDate: '2023-08-19', avatar: 'KO' },
  { id: 'user_010', name: 'Nana Agyeman', phone: '+233 24 101 3388', email: 'nana.agyeman@example.com', kycStatus: 'Approved', walletBalance: 3015.80, status: 'Active', joinedDate: '2023-09-05', avatar: 'NA' },
  { id: 'user_011', name: 'Kojo Addai', phone: '+233 57 442 1100', email: 'kojo.addai@example.com', kycStatus: 'Approved', walletBalance: 1880.45, status: 'Inactive', joinedDate: '2022-12-15', avatar: 'KA' },
  { id: 'user_012', name: 'Yaa Appiah', phone: '+233 26 440 9981', email: 'yaa.appiah@example.com', kycStatus: 'Rejected', walletBalance: 0, status: 'Inactive', joinedDate: '2024-03-27', avatar: 'YA' },
  { id: 'user_013', name: 'Kwabena Ofori', phone: '+233 55 778 1204', email: 'kwabena.ofori@example.com', kycStatus: 'Approved', walletBalance: 1655.20, status: 'Active', joinedDate: '2023-07-11', avatar: 'KO' },
  { id: 'user_014', name: 'Esi Boateng', phone: '+233 24 908 2245', email: 'esi.boateng@example.com', kycStatus: 'Approved', walletBalance: 2120.00, status: 'Active', joinedDate: '2023-11-19', avatar: 'EB' },
  { id: 'user_015', name: 'Rita Amankwah', phone: '+233 20 667 3351', email: 'rita.amankwah@example.com', kycStatus: 'Pending', walletBalance: 980.75, status: 'Active', joinedDate: '2024-01-28', avatar: 'RA' },
  { id: 'user_016', name: 'Kojo Nyarko', phone: '+233 27 311 7700', email: 'kojo.nyarko@example.com', kycStatus: 'Approved', walletBalance: 1425.60, status: 'Active', joinedDate: '2022-10-22', avatar: 'KN' },
];

export const mockSusuGroups = [
  {
    id: 'group_001',
    name: 'Unity Savers Group',
    members: 5,
    contributionAmount: 200,
    frequency: 'Weekly',
    cycleProgress: 60,
    totalPooled: 3000,
    nextPayoutDate: '2025-02-02',
    status: 'Active',
    membersList: [
      { name: 'Kwame Mensah', currentRotation: 'Paid', amount: 1000 },
      { name: 'Ama Darko', currentRotation: 'Next', amount: 1000 },
      { name: 'Kofi Asante', currentRotation: 'Pending', amount: 1000 },
    ],
  },
  {
    id: 'group_002',
    name: 'Women Empowerment Circle',
    members: 4,
    contributionAmount: 150,
    frequency: 'Bi-weekly',
    cycleProgress: 45,
    totalPooled: 2400,
    nextPayoutDate: '2025-02-10',
    status: 'Active',
    membersList: [
      { name: 'Akua Frimpong', currentRotation: 'Pending', amount: 600 },
      { name: 'Efua Adjei', currentRotation: 'Paid', amount: 600 },
      { name: 'Adwoa Mensah', currentRotation: 'Next', amount: 600 },
    ],
  },
  {
    id: 'group_003',
    name: 'Traders Alliance',
    members: 6,
    contributionAmount: 300,
    frequency: 'Monthly',
    cycleProgress: 50,
    totalPooled: 5400,
    nextPayoutDate: '2025-02-18',
    status: 'Active',
    membersList: [
      { name: 'Kwesi Owusu', currentRotation: 'Paid', amount: 1800 },
      { name: 'Nana Agyeman', currentRotation: 'Next', amount: 1800 },
      { name: 'Kojo Addai', currentRotation: 'Pending', amount: 1800 },
    ],
  },
  {
    id: 'group_public_001',
    name: 'Accra Market Vendors',
    members: 5,
    contributionAmount: 180,
    frequency: 'Weekly',
    cycleProgress: 25,
    totalPooled: 2250,
    nextPayoutDate: '2025-01-28',
    status: 'Active',
    membersList: [
      { name: 'Esi Boateng', currentRotation: 'Paid', amount: 900 },
      { name: 'Rita Amankwah', currentRotation: 'Pending', amount: 900 },
      { name: 'Kojo Nyarko', currentRotation: 'Next', amount: 900 },
    ],
  },
  {
    id: 'group_public_002',
    name: 'Ashesi Alumni Builders',
    members: 4,
    contributionAmount: 400,
    frequency: 'Bi-weekly',
    cycleProgress: 15,
    totalPooled: 2400,
    nextPayoutDate: '2025-02-05',
    status: 'Active',
    membersList: [
      { name: 'Kwabena Ofori', currentRotation: 'Pending', amount: 1600 },
      { name: 'Kojo Nyarko', currentRotation: 'Next', amount: 1600 },
    ],
  },
  {
    id: 'group_public_003',
    name: 'Cape Coast Teachers Fund',
    members: 6,
    contributionAmount: 220,
    frequency: 'Monthly',
    cycleProgress: 70,
    totalPooled: 9240,
    nextPayoutDate: '2025-01-25',
    status: 'Completing',
    membersList: [
      { name: 'Agnes Quaye', currentRotation: 'Paid', amount: 1320 },
      { name: 'Naana Eshun', currentRotation: 'Paid', amount: 1320 },
      { name: 'Felix Aidoo', currentRotation: 'Next', amount: 1320 },
    ],
  },
];

export const mockTransactions = [
  { id: 'TXN-24021', date: '2025-01-15 09:45', user: 'Kwame Mensah', type: 'Deposit', amount: 500.50, status: 'Success', reference: 'DEP-882154', channel: 'MTN MoMo', description: 'Wallet top-up via MTN', fee: 3.50 },
  { id: 'TXN-24020', date: '2025-01-15 09:10', user: 'Ama Darko', type: 'Deposit', amount: 320.00, status: 'Success', reference: 'DEP-771203', channel: 'Vodafone Cash', description: 'Wallet funding for Unity Savers', fee: 2.40 },
  { id: 'TXN-24019', date: '2025-01-14 18:22', user: 'Kofi Asante', type: 'Deposit', amount: 680.00, status: 'Success', reference: 'DEP-661204', channel: 'Bank Transfer', description: 'Float deposit for payouts', fee: 4.10 },
  { id: 'TXN-24018', date: '2025-01-14 17:05', user: 'Abena Osei', type: 'Deposit', amount: 250.00, status: 'Success', reference: 'DEP-551204', channel: 'MTN MoMo', description: 'Weekly contribution funding', fee: 1.80 },
  { id: 'TXN-24017', date: '2025-01-14 16:40', user: 'Yaw Boateng', type: 'Deposit', amount: 180.00, status: 'Failed', reference: 'DEP-441205', channel: 'AirtelTigo Money', description: 'Deposit declined - KYC hold', fee: 0 },
  { id: 'TXN-24016', date: '2025-01-14 15:58', user: 'Akua Frimpong', type: 'Deposit', amount: 210.00, status: 'Pending', reference: 'DEP-331205', channel: 'MTN MoMo', description: 'Awaiting mobile confirmation', fee: 0 },
  { id: 'TXN-24015', date: '2025-01-14 12:26', user: 'Efua Adjei', type: 'Deposit', amount: 720.00, status: 'Success', reference: 'DEP-221205', channel: 'Bank Transfer', description: 'Business capital injection', fee: 4.75 },
  { id: 'TXN-24014', date: '2025-01-14 11:42', user: 'Adwoa Mensah', type: 'Deposit', amount: 150.00, status: 'Success', reference: 'DEP-221187', channel: 'MTN MoMo', description: 'Wallet boost before cycle', fee: 1.20 },
  { id: 'TXN-24013', date: '2025-01-13 19:33', user: 'Kwesi Owusu', type: 'Deposit', amount: 540.00, status: 'Success', reference: 'DEP-118530', channel: 'Bank Transfer', description: 'Traders Alliance float top-up', fee: 3.60 },
  { id: 'TXN-24012', date: '2025-01-13 09:18', user: 'Nana Agyeman', type: 'Deposit', amount: 810.00, status: 'Success', reference: 'DEP-771110', channel: 'MTN MoMo', description: 'Advance funding for payouts', fee: 5.20 },
  { id: 'TXN-24011', date: '2025-01-13 08:47', user: 'Kwame Mensah', type: 'Contribution', amount: 200.00, status: 'Success', reference: 'CIRC-8821', channel: 'Wallet Transfer', description: 'Unity Savers weekly contribution' },
  { id: 'TXN-24010', date: '2025-01-12 19:55', user: 'Akua Frimpong', type: 'Contribution', amount: 150.00, status: 'Pending', reference: 'CIRC-7710', channel: 'Wallet Transfer', description: 'Women Empowerment cycle 2' },
  { id: 'TXN-24009', date: '2025-01-12 18:40', user: 'Efua Adjei', type: 'Contribution', amount: 200.00, status: 'Success', reference: 'CIRC-6609', channel: 'Wallet Transfer', description: 'Women Empowerment cycle 2' },
  { id: 'TXN-24008', date: '2025-01-12 17:32', user: 'Kwesi Owusu', type: 'Contribution', amount: 300.00, status: 'Success', reference: 'CIRC-5508', channel: 'Wallet Transfer', description: 'Traders Alliance cycle 4' },
  { id: 'TXN-24007', date: '2025-01-11 16:14', user: 'Adwoa Mensah', type: 'Contribution', amount: 180.00, status: 'Success', reference: 'CIRC-4407', channel: 'Wallet Transfer', description: 'Accra Market Vendors cycle 1' },
  { id: 'TXN-24006', date: '2025-01-11 14:09', user: 'Nana Agyeman', type: 'Contribution', amount: 220.00, status: 'Success', reference: 'CIRC-3306', channel: 'Wallet Transfer', description: 'Traders Alliance cycle 4' },
  { id: 'TXN-24005', date: '2025-01-11 10:48', user: 'Kwame Mensah', type: 'Withdrawal', amount: 400.00, status: 'Success', reference: 'WDR-2205', channel: 'GTBank', description: 'Payout to business account', fee: 2.80 },
  { id: 'TXN-24004', date: '2025-01-10 21:20', user: 'Ama Darko', type: 'Withdrawal', amount: 250.00, status: 'Pending', reference: 'WDR-1104', channel: 'MTN MoMo', description: 'Cash out for vendor payments', fee: 0 },
  { id: 'TXN-24003', date: '2025-01-10 20:04', user: 'Yaw Boateng', type: 'Withdrawal', amount: 500.00, status: 'Failed', reference: 'WDR-0003', channel: 'Bank Transfer', description: 'Withdrawal rejected - compliance', fee: 0 },
  { id: 'TXN-24002', date: '2025-01-10 18:42', user: 'Kofi Asante', type: 'Payout', amount: 1000.00, status: 'Success', reference: 'PAY-1174', channel: 'Group Wallet', description: 'Unity Savers cycle payout', fee: 0 },
  { id: 'TXN-24001', date: '2025-01-10 17:33', user: 'Kwabena Ofori', type: 'Savings', amount: 175.00, status: 'Success', reference: 'SAVE-5521', channel: 'Wallet Transfer', description: 'Education fund auto-save' },
];

export const mockDisputes = [
  { id: 'DIS-1001', title: 'Missing Contribution Payment', user: 'Abena Osei', group: 'Unity Savers Group', status: 'Open', date: '2025-01-08', priority: 'High' },
  { id: 'DIS-1002', title: 'Delayed Payout Issue', user: 'Ama Darko', group: 'Women Empowerment Circle', status: 'In Review', date: '2025-01-07', priority: 'Medium' },
  { id: 'DIS-1003', title: 'Incorrect Amount Deducted', user: 'Kwabena Ofori', group: 'Ashesi Alumni Builders', status: 'Resolved', date: '2025-01-05', priority: 'Low' },
  { id: 'DIS-1004', title: 'Withdrawal Compliance Hold', user: 'Yaw Boateng', group: 'Unity Savers Group', status: 'Open', date: '2025-01-09', priority: 'High' },
  { id: 'DIS-1005', title: 'Invite Reminder Escalation', user: 'Akua Frimpong', group: 'Women Empowerment Circle', status: 'In Review', date: '2025-01-06', priority: 'Medium' },
];

export const mockNotifications = [
  { id: 1, type: 'alert', message: 'Withdrawal hold: Yaw Boateng requires compliance review', time: '3 mins ago', read: false },
  { id: 2, type: 'success', message: 'Unity Savers Group cycle payout of GH₵ 1,000 completed', time: '25 mins ago', read: false },
  { id: 3, type: 'warning', message: 'Pending deposit confirmation for Akua Frimpong', time: '1 hour ago', read: false },
  { id: 4, type: 'info', message: '13 active members reached 70% savings milestones this week', time: '4 hours ago', read: true },
  { id: 5, type: 'success', message: 'New public group Accra Market Vendors added 5 members', time: 'Yesterday', read: true },
  { id: 6, type: 'info', message: 'Reminder: Send invites follow-up for Women Empowerment Circle', time: '2 days ago', read: true },
];

// Analytics data for charts
export const dailyTransactionsData = [
  { date: 'Jan 10', amount: 2450 },
  { date: 'Jan 11', amount: 1820 },
  { date: 'Jan 12', amount: 1650 },
  { date: 'Jan 13', amount: 2150 },
  { date: 'Jan 14', amount: 2330 },
  { date: 'Jan 15', amount: 820 },
];

export const userStatusData = [
  { name: 'Active', value: 13, fill: 'hsl(174, 64%, 40%)' },
  { name: 'Inactive', value: 2, fill: 'hsl(220, 9%, 46%)' },
  { name: 'Suspended', value: 1, fill: 'hsl(0, 84%, 60%)' },
];

export const monthlyRevenueData = [
  { month: 'Aug', revenue: 41200 },
  { month: 'Sep', revenue: 43850 },
  { month: 'Oct', revenue: 46540 },
  { month: 'Nov', revenue: 49820 },
  { month: 'Dec', revenue: 52310 },
  { month: 'Jan', revenue: 54760 },
];

export const groupGrowthData = [
  { month: 'Aug', groups: 48 },
  { month: 'Sep', groups: 55 },
  { month: 'Oct', groups: 62 },
  { month: 'Nov', groups: 70 },
  { month: 'Dec', groups: 78 },
  { month: 'Jan', groups: 84 },
];
