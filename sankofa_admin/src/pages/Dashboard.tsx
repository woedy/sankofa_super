import { Users, Wallet, TrendingUp, DollarSign } from 'lucide-react';
import { LineChart, Line, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import KPICard from '@/components/dashboard/KPICard';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { dailyTransactionsData, userStatusData, mockNotifications, mockUsers, mockSusuGroups, mockTransactions } from '@/lib/mockData';
import { StatusBadge } from '@/components/ui/badge-variants';
import { Bell } from 'lucide-react';

export default function Dashboard() {
  const formatNumber = (value: number) => value.toLocaleString();
  const formatCurrency = (value: number) =>
    `GH₵ ${value.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

  const totalUsers = mockUsers.length;
  const activeGroups = mockSusuGroups.filter((group) => group.status !== 'Archived').length;
  const totalDeposits = mockTransactions
    .filter((transaction) => transaction.type === 'Deposit' && transaction.status !== 'Failed')
    .reduce((sum, transaction) => sum + transaction.amount, 0);
  const platformRevenue = mockTransactions
    .filter((transaction) => transaction.status === 'Success')
    .reduce((sum, transaction) => sum + (transaction.fee ?? 0), 0);

  return (
    <div className="space-y-6">
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <KPICard
          title="Total Users"
          value={formatNumber(totalUsers)}
          change="16 enriched member records"
          trend="up"
          icon={Users}
        />
        <KPICard
          title="Active Susu Groups"
          value={formatNumber(activeGroups)}
          change="Seed data synced with app groups"
          trend="up"
          icon={Wallet}
        />
        <KPICard
          title="Total Deposits"
          value={formatCurrency(totalDeposits)}
          change="Successful & pending deposit volume"
          trend="up"
          icon={TrendingUp}
        />
        <KPICard
          title="Platform Revenue"
          value={formatCurrency(platformRevenue)}
          change="Summed from transaction fees"
          trend="up"
          icon={DollarSign}
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-7">
        <Card className="lg:col-span-4 shadow-custom-md">
          <CardHeader>
            <CardTitle>Daily Transactions</CardTitle>
            <CardDescription>Transaction volume over the past week</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={dailyTransactionsData}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                <XAxis dataKey="date" className="text-muted-foreground" />
                <YAxis className="text-muted-foreground" />
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: 'hsl(var(--card))', 
                    border: '1px solid hsl(var(--border))',
                    borderRadius: '8px'
                  }}
                />
                <Line 
                  type="monotone" 
                  dataKey="amount" 
                  stroke="hsl(var(--primary))" 
                  strokeWidth={2}
                  dot={{ fill: 'hsl(var(--primary))', r: 4 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card className="lg:col-span-3 shadow-custom-md">
          <CardHeader>
            <CardTitle>User Status</CardTitle>
            <CardDescription>Distribution of user activity</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={userStatusData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {userStatusData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.fill} />
                  ))}
                </Pie>
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: 'hsl(var(--card))', 
                    border: '1px solid hsl(var(--border))',
                    borderRadius: '8px'
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      <Card className="shadow-custom-md">
        <CardHeader>
          <div className="flex items-center gap-2">
            <Bell className="h-5 w-5 text-primary" />
            <CardTitle>Recent Notifications</CardTitle>
          </div>
          <CardDescription>Latest platform activities and alerts</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {mockNotifications.map((notification) => (
              <div 
                key={notification.id} 
                className="flex items-start gap-4 rounded-lg border border-border p-4 transition-smooth hover:bg-muted/50"
              >
                <div className={`mt-1 h-2 w-2 rounded-full ${
                  notification.type === 'alert' ? 'bg-destructive' :
                  notification.type === 'success' ? 'bg-success' :
                  notification.type === 'warning' ? 'bg-warning' :
                  'bg-primary'
                }`} />
                <div className="flex-1 space-y-1">
                  <p className="text-sm font-medium text-foreground">{notification.message}</p>
                  <p className="text-xs text-muted-foreground">{notification.time}</p>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
