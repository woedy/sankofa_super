import { useMemo, useState, useEffect } from 'react';
import { ColumnDef, flexRender, getCoreRowModel, useReactTable } from '@tanstack/react-table';
import { BadgeCheckIcon, ClockIcon, ArrowDownIcon, ArrowUpIcon } from 'lucide-react';
import { transactionService } from '../../services/transactionService';
import type { Transaction } from '../../lib/types';

const Transactions = () => {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('All');

  useEffect(() => {
    loadTransactions();
  }, []);

  const loadTransactions = async () => {
    try {
      const data = await transactionService.getTransactions();
      setTransactions(data);
    } catch (error) {
      console.error('Failed to load transactions:', error);
    } finally {
      setLoading(false);
    }
  };

  const data = useMemo(() => {
    if (filter === 'All') return transactions;
    return transactions.filter((transaction) => transaction.type.toLowerCase() === filter.toLowerCase());
  }, [filter, transactions]);

  const columns = useMemo<ColumnDef<Transaction>[]>(
    () => [
      {
        accessorKey: 'type',
        header: 'Type',
        cell: ({ getValue }) => <span className="font-semibold text-slate-900 dark:text-white">{getValue<string>()}</span>
      },
      {
        accessorKey: 'createdAt',
        header: 'Date',
        cell: ({ getValue }) => <span className="text-sm text-slate-500 dark:text-slate-400">{new Date(getValue<string>()).toLocaleDateString()}</span>
      },
      {
        accessorKey: 'channel',
        header: 'Channel',
        cell: ({ getValue }) => <span className="text-sm text-slate-500 dark:text-slate-400">{getValue<string>() || 'N/A'}</span>
      },
      {
        accessorKey: 'amount',
        header: 'Amount',
        cell: ({ getValue }) => (
          <span className="font-semibold text-slate-900 dark:text-white">GH₵{Number(getValue<number>()).toLocaleString()}</span>
        )
      },
      {
        accessorKey: 'status',
        header: 'Status',
        cell: ({ getValue }) => {
          const value = getValue<string>();
          const Icon = value === 'completed' ? BadgeCheckIcon : ClockIcon;
          const styles = value === 'completed' ? 'bg-emerald-500/10 text-emerald-600' : 'bg-amber-500/10 text-amber-600';
          return (
            <span className={`inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-semibold capitalize ${styles}`}>
              <Icon size={14} /> {value}
            </span>
          );
        }
      },
      {
        accessorKey: 'reference',
        header: 'Reference',
        cell: ({ getValue }) => <span className="text-sm text-slate-500 dark:text-slate-400">{getValue<string>() || '-'}</span>
      }
    ],
    []
  );

  const table = useReactTable({ data, columns, getCoreRowModel: getCoreRowModel() });

  const filters = ['All', 'Deposit', 'Contribution', 'Withdrawal'];

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="text-center">
          <div className="mb-4 h-12 w-12 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
          <p className="text-sm text-slate-600 dark:text-slate-400">Loading transactions...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <header className="flex flex-col gap-2">
        <p className="text-sm font-semibold uppercase tracking-widest text-primary">Transactions</p>
        <h1 className="text-3xl font-bold text-slate-900 dark:text-white">Wallet history</h1>
        <p className="text-sm text-slate-600 dark:text-slate-300">
          Review deposits, contributions, and withdrawals with the same detail available in the mobile modal experience.
        </p>
      </header>

      <div className="flex flex-wrap gap-3">
        {filters.map((item) => (
          <button
            key={item}
            onClick={() => setFilter(item)}
            className={`inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-semibold transition ${
              filter === item
                ? 'border-primary bg-primary text-primary-foreground shadow-lg shadow-primary/20'
                : 'border-slate-200 bg-white text-slate-600 hover:border-primary hover:text-primary dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300'
            }`}
          >
            {item === 'Deposit' && <ArrowDownIcon size={16} />}
            {item === 'Withdrawal' && <ArrowUpIcon size={16} />}
            {item}
          </button>
        ))}
      </div>

      <div className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-lg dark:border-slate-800 dark:bg-slate-900">
        <table className="min-w-full divide-y divide-slate-200 dark:divide-slate-800">
          <thead className="bg-slate-50/80 text-left text-xs font-semibold uppercase tracking-wider text-slate-500 dark:bg-slate-900/80 dark:text-slate-400">
            {table.getHeaderGroups().map((headerGroup) => (
              <tr key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <th key={header.id} className="px-4 py-3">
                    {header.isPlaceholder ? null : flexRender(header.column.columnDef.header, header.getContext())}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody className="divide-y divide-slate-200 text-sm dark:divide-slate-800">
            {table.getRowModel().rows.map((row) => (
              <tr key={row.id} className="hover:bg-slate-50/60 dark:hover:bg-slate-900/60">
                {row.getVisibleCells().map((cell) => (
                  <td key={cell.id} className="px-4 py-4">
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Transactions;
