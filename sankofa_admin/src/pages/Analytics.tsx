import { useState } from 'react';
import { TrendingUp, Users, Wallet, DollarSign } from 'lucide-react';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { monthlyRevenueData, groupGrowthData } from '@/lib/mockData';
import KPICard from '@/components/dashboard/KPICard';

export default function Analytics() {
  const [timeRange, setTimeRange] = useState('monthly');

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold text-foreground">Analytics Dashboard</h2>
          <p className="text-muted-foreground">Track growth metrics and platform performance</p>
        </div>
        <Tabs value={timeRange} onValueChange={setTimeRange}>
          <TabsList>
            <TabsTrigger value="daily">Daily</TabsTrigger>
            <TabsTrigger value="weekly">Weekly</TabsTrigger>
            <TabsTrigger value="monthly">Monthly</TabsTrigger>
          </TabsList>
        </Tabs>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <KPICard
          title="Monthly Revenue"
          value="GH₵ 85,340"
          change="+23.4% vs last month"
          trend="up"
          icon={DollarSign}
        />
        <KPICard
          title="New Users"
          value="148"
          change="+12.5% vs last month"
          trend="up"
          icon={Users}
        />
        <KPICard
          title="New Groups"
          value="13"
          change="+8 new groups"
          trend="up"
          icon={Wallet}
        />
        <KPICard
          title="Avg. Transaction"
          value="GH₵ 285"
          change="+5.2% vs last month"
          trend="up"
          icon={TrendingUp}
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="shadow-custom-md">
          <CardHeader>
            <CardTitle>Revenue Growth</CardTitle>
            <CardDescription>Platform revenue over the past 6 months</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={350}>
              <BarChart data={monthlyRevenueData}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                <XAxis dataKey="month" className="text-muted-foreground" />
                <YAxis className="text-muted-foreground" />
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: 'hsl(var(--card))', 
                    border: '1px solid hsl(var(--border))',
                    borderRadius: '8px'
                  }}
                  formatter={(value) => [`GH₵ ${value}`, 'Revenue']}
                />
                <Legend />
                <Bar 
                  dataKey="revenue" 
                  fill="hsl(var(--primary))" 
                  radius={[8, 8, 0, 0]}
                  name="Revenue"
                />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card className="shadow-custom-md">
          <CardHeader>
            <CardTitle>Group Growth</CardTitle>
            <CardDescription>Active susu groups over the past 6 months</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={350}>
              <LineChart data={groupGrowthData}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                <XAxis dataKey="month" className="text-muted-foreground" />
                <YAxis className="text-muted-foreground" />
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: 'hsl(var(--card))', 
                    border: '1px solid hsl(var(--border))',
                    borderRadius: '8px'
                  }}
                  formatter={(value) => [`${value} groups`, 'Total Groups']}
                />
                <Legend />
                <Line 
                  type="monotone" 
                  dataKey="groups" 
                  stroke="hsl(var(--secondary))" 
                  strokeWidth={3}
                  dot={{ fill: 'hsl(var(--secondary))', r: 5 }}
                  name="Total Groups"
                />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Key Performance Indicators</CardTitle>
          <CardDescription>Detailed metrics breakdown for the current month</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-3">
            <div className="rounded-lg border border-border p-6 space-y-2">
              <p className="text-sm font-medium text-muted-foreground">Total Transaction Volume</p>
              <p className="text-3xl font-bold text-foreground">GH₵ 1.2M</p>
              <p className="text-sm text-success">+18.2% from last month</p>
            </div>
            <div className="rounded-lg border border-border p-6 space-y-2">
              <p className="text-sm font-medium text-muted-foreground">Average Group Size</p>
              <p className="text-3xl font-bold text-foreground">11.2</p>
              <p className="text-sm text-success">+0.8 members</p>
            </div>
            <div className="rounded-lg border border-border p-6 space-y-2">
              <p className="text-sm font-medium text-muted-foreground">Platform Utilization</p>
              <p className="text-3xl font-bold text-foreground">83.5%</p>
              <p className="text-sm text-success">+5.3% from last month</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
