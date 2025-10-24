import { NavLink } from 'react-router-dom';
import { 
  LayoutDashboard,
  Users,
  CircleDollarSign,
  Receipt,
  BarChart3,
  AlertTriangle,
  Settings,
  Wallet,
  Banknote,
} from 'lucide-react';
import { cn } from '@/lib/utils';

const navigation = [
  { name: 'Dashboard', href: '/', icon: LayoutDashboard },
  { name: 'Users', href: '/users', icon: Users },
  { name: 'Susu Groups', href: '/groups', icon: Wallet },
  { name: 'Cashflow Ops', href: '/cashflow', icon: Banknote },
  { name: 'Transactions', href: '/transactions', icon: Receipt },
  { name: 'Analytics', href: '/analytics', icon: BarChart3 },
  { name: 'Disputes', href: '/disputes', icon: AlertTriangle },
  { name: 'Settings', href: '/settings', icon: Settings },
];

export default function Sidebar() {
  return (
    <aside className="sticky top-0 z-20 flex h-screen w-64 flex-col border-r border-border bg-card">
      <div className="flex h-16 items-center gap-2 border-b border-border px-6">
        <CircleDollarSign className="h-8 w-8 text-primary" />
        <div>
          <h1 className="text-lg font-bold text-foreground">Susu Admin</h1>
          <p className="text-xs text-muted-foreground">Ghana Digital Savings</p>
        </div>
      </div>

      <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4">
        {navigation.map((item) => (
          <NavLink
            key={item.name}
            to={item.href}
            end={item.href === '/'}
            className={({ isActive }) =>
              cn(
                'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-smooth',
                isActive
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:bg-muted hover:text-foreground'
              )
            }
          >
            <item.icon className="h-5 w-5" />
            {item.name}
          </NavLink>
        ))}
      </nav>

      <div className="border-t border-border p-4">
        <div className="flex items-center gap-3 rounded-lg bg-muted p-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground font-semibold">
            AM
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-foreground truncate">Admin User</p>
            <p className="text-xs text-muted-foreground truncate">admin@susu.gh</p>
          </div>
        </div>
      </div>
    </aside>
  );
}
