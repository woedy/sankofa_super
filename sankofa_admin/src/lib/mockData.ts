// Mock data for the Susu Admin Dashboard

export const mockUsers = [
  { id: 1, name: 'Kwame Mensah', phone: '+233 24 123 4567', email: 'kwame.mensah@email.com', kycStatus: 'Approved', walletBalance: 2450.00, status: 'Active', joinedDate: '2024-01-15', avatar: 'KM' },
  { id: 2, name: 'Ama Asante', phone: '+233 20 987 6543', email: 'ama.asante@email.com', kycStatus: 'Pending', walletBalance: 1200.50, status: 'Active', joinedDate: '2024-02-20', avatar: 'AA' },
  { id: 3, name: 'Kofi Boateng', phone: '+233 55 246 8135', email: 'kofi.b@email.com', kycStatus: 'Approved', walletBalance: 3100.00, status: 'Active', joinedDate: '2024-01-10', avatar: 'KB' },
  { id: 4, name: 'Akua Adjei', phone: '+233 27 135 7924', email: 'akua.adjei@email.com', kycStatus: 'Approved', walletBalance: 890.25, status: 'Suspended', joinedDate: '2024-03-05', avatar: 'AA' },
  { id: 5, name: 'Yaw Osei', phone: '+233 50 864 2097', email: 'yaw.osei@email.com', kycStatus: 'Rejected', walletBalance: 0.00, status: 'Inactive', joinedDate: '2024-04-12', avatar: 'YO' },
  { id: 6, name: 'Abena Owusu', phone: '+233 24 753 1864', email: 'abena.o@email.com', kycStatus: 'Approved', walletBalance: 1750.80, status: 'Active', joinedDate: '2024-02-28', avatar: 'AO' },
  { id: 7, name: 'Kwabena Antwi', phone: '+233 26 951 3578', email: 'kwabena.antwi@email.com', kycStatus: 'Pending', walletBalance: 520.00, status: 'Active', joinedDate: '2024-04-18', avatar: 'KA' },
  { id: 8, name: 'Efua Gyamfi', phone: '+233 54 682 4097', email: 'efua.g@email.com', kycStatus: 'Approved', walletBalance: 4200.00, status: 'Active', joinedDate: '2024-01-25', avatar: 'EG' },
];

export const mockSusuGroups = [
  { 
    id: 1, 
    name: 'Market Women\'s Circle', 
    members: 12, 
    contributionAmount: 50, 
    frequency: 'Weekly',
    cycleProgress: 75, 
    totalPooled: 3600,
    nextPayoutDate: '2025-01-15',
    status: 'Active',
    membersList: [
      { name: 'Ama Asante', currentRotation: 'Paid', amount: 600 },
      { name: 'Akua Adjei', currentRotation: 'Next', amount: 600 },
      { name: 'Abena Owusu', currentRotation: 'Pending', amount: 600 },
    ]
  },
  { 
    id: 2, 
    name: 'Tech Professionals Group', 
    members: 8, 
    contributionAmount: 200, 
    frequency: 'Monthly',
    cycleProgress: 40, 
    totalPooled: 4800,
    nextPayoutDate: '2025-02-01',
    status: 'Active',
    membersList: [
      { name: 'Kwame Mensah', currentRotation: 'Paid', amount: 1600 },
      { name: 'Kofi Boateng', currentRotation: 'Paid', amount: 1600 },
      { name: 'Yaw Osei', currentRotation: 'Next', amount: 1600 },
    ]
  },
  { 
    id: 3, 
    name: 'Teachers\' Savings Circle', 
    members: 15, 
    contributionAmount: 100, 
    frequency: 'Bi-weekly',
    cycleProgress: 60, 
    totalPooled: 9000,
    nextPayoutDate: '2025-01-22',
    status: 'Active',
    membersList: [
      { name: 'Efua Gyamfi', currentRotation: 'Paid', amount: 1500 },
      { name: 'Kwabena Antwi', currentRotation: 'Next', amount: 1500 },
    ]
  },
  { 
    id: 4, 
    name: 'Young Entrepreneurs Hub', 
    members: 10, 
    contributionAmount: 150, 
    frequency: 'Monthly',
    cycleProgress: 20, 
    totalPooled: 3000,
    nextPayoutDate: '2025-02-10',
    status: 'Active',
    membersList: []
  },
  { 
    id: 5, 
    name: 'Nurses\' Support Group', 
    members: 6, 
    contributionAmount: 75, 
    frequency: 'Weekly',
    cycleProgress: 90, 
    totalPooled: 2700,
    nextPayoutDate: '2025-01-18',
    status: 'Completing',
    membersList: []
  },
  { 
    id: 6, 
    name: 'Artisans\' Collective', 
    members: 9, 
    contributionAmount: 80, 
    frequency: 'Weekly',
    cycleProgress: 55, 
    totalPooled: 3960,
    nextPayoutDate: '2025-01-25',
    status: 'Active',
    membersList: []
  },
];

export const mockTransactions = [
  { id: 1, date: '2025-01-10 14:32', user: 'Kwame Mensah', type: 'Deposit', amount: 500.00, status: 'Success', reference: 'TXN001234567' },
  { id: 2, date: '2025-01-10 13:15', user: 'Ama Asante', type: 'Contribution', amount: 50.00, status: 'Success', reference: 'TXN001234566' },
  { id: 3, date: '2025-01-10 12:45', user: 'Kofi Boateng', type: 'Withdrawal', amount: 1000.00, status: 'Pending', reference: 'TXN001234565' },
  { id: 4, date: '2025-01-10 11:20', user: 'Akua Adjei', type: 'Deposit', amount: 200.00, status: 'Success', reference: 'TXN001234564' },
  { id: 5, date: '2025-01-10 10:05', user: 'Yaw Osei', type: 'Contribution', amount: 200.00, status: 'Failed', reference: 'TXN001234563' },
  { id: 6, date: '2025-01-09 16:50', user: 'Abena Owusu', type: 'Deposit', amount: 750.00, status: 'Success', reference: 'TXN001234562' },
  { id: 7, date: '2025-01-09 15:30', user: 'Kwabena Antwi', type: 'Contribution', amount: 100.00, status: 'Success', reference: 'TXN001234561' },
  { id: 8, date: '2025-01-09 14:15', user: 'Efua Gyamfi', type: 'Withdrawal', amount: 2000.00, status: 'Success', reference: 'TXN001234560' },
  { id: 9, date: '2025-01-09 13:00', user: 'Kwame Mensah', type: 'Contribution', amount: 200.00, status: 'Success', reference: 'TXN001234559' },
  { id: 10, date: '2025-01-09 11:45', user: 'Ama Asante', type: 'Deposit', amount: 300.00, status: 'Success', reference: 'TXN001234558' },
];

export const mockDisputes = [
  { id: 1, title: 'Missing Contribution Payment', user: 'Akua Adjei', group: 'Market Women\'s Circle', status: 'Open', date: '2025-01-08', priority: 'High' },
  { id: 2, title: 'Delayed Payout Issue', user: 'Yaw Osei', group: 'Tech Professionals Group', status: 'In Review', date: '2025-01-07', priority: 'Medium' },
  { id: 3, title: 'Incorrect Amount Deducted', user: 'Kwabena Antwi', group: 'Teachers\' Savings Circle', status: 'Resolved', date: '2025-01-05', priority: 'Low' },
  { id: 4, title: 'Group Member Complaint', user: 'Abena Owusu', group: 'Young Entrepreneurs Hub', status: 'Open', date: '2025-01-09', priority: 'High' },
];

export const mockNotifications = [
  { id: 1, type: 'alert', message: 'New KYC verification pending for Ama Asante', time: '5 mins ago', read: false },
  { id: 2, type: 'success', message: 'Market Women\'s Circle completed payout cycle', time: '1 hour ago', read: false },
  { id: 3, type: 'warning', message: 'High transaction volume detected', time: '2 hours ago', read: true },
  { id: 4, type: 'info', message: 'System maintenance scheduled for tonight', time: '1 day ago', read: true },
];

// Analytics data for charts
export const dailyTransactionsData = [
  { date: 'Jan 4', amount: 12450 },
  { date: 'Jan 5', amount: 15230 },
  { date: 'Jan 6', amount: 18900 },
  { date: 'Jan 7', amount: 14560 },
  { date: 'Jan 8', amount: 21340 },
  { date: 'Jan 9', amount: 19870 },
  { date: 'Jan 10', amount: 23450 },
];

export const userStatusData = [
  { name: 'Active', value: 856, fill: 'hsl(174, 64%, 40%)' },
  { name: 'Inactive', value: 124, fill: 'hsl(220, 9%, 46%)' },
  { name: 'Suspended', value: 45, fill: 'hsl(0, 84%, 60%)' },
];

export const monthlyRevenueData = [
  { month: 'Aug', revenue: 45000 },
  { month: 'Sep', revenue: 52000 },
  { month: 'Oct', revenue: 61000 },
  { month: 'Nov', revenue: 58000 },
  { month: 'Dec', revenue: 73000 },
  { month: 'Jan', revenue: 85000 },
];

export const groupGrowthData = [
  { month: 'Aug', groups: 45 },
  { month: 'Sep', groups: 52 },
  { month: 'Oct', groups: 61 },
  { month: 'Nov', groups: 68 },
  { month: 'Dec', groups: 79 },
  { month: 'Jan', groups: 92 },
];
