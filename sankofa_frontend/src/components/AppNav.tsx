import { NavLink } from 'react-router-dom';
import { BellIcon, HomeIcon, LayersIcon, PiggyBankIcon, ReceiptIcon, UserIcon, LifeBuoyIcon } from 'lucide-react';

const navItems = [
  { to: '/app/home', label: 'Home', icon: HomeIcon },
  { to: '/app/groups', label: 'Groups', icon: LayersIcon },
  { to: '/app/savings', label: 'Savings', icon: PiggyBankIcon },
  { to: '/app/transactions', label: 'Transactions', icon: ReceiptIcon },
  { to: '/app/notifications', label: 'Notifications', icon: BellIcon },
  { to: '/app/support', label: 'Support', icon: LifeBuoyIcon },
  { to: '/app/profile', label: 'Profile', icon: UserIcon }
];

const AppNav = () => {
  return (
    <nav className="flex flex-wrap items-center gap-2">
      {navItems.map((item) => (
        <NavLink
          key={item.to}
          to={item.to}
          className={({ isActive }) =>
            `flex items-center gap-2 rounded-full px-4 py-2 text-sm font-medium transition ${
              isActive
                ? 'bg-primary text-primary-foreground shadow-lg shadow-primary/20'
                : 'bg-white/70 text-slate-600 hover:bg-white hover:text-primary dark:bg-slate-900/60 dark:text-slate-300 dark:hover:bg-slate-800'
            }`
          }
        >
          <item.icon size={16} />
          <span>{item.label}</span>
        </NavLink>
      ))}
    </nav>
  );
};

export default AppNav;
