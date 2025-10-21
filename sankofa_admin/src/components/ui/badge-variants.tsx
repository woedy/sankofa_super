import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';

interface StatusBadgeProps {
  status: string;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const variants: Record<string, string> = {
    'Success': 'bg-success/10 text-success border-success/20',
    'Approved': 'bg-success/10 text-success border-success/20',
    'Active': 'bg-success/10 text-success border-success/20',
    'Pending': 'bg-warning/10 text-warning border-warning/20',
    'Failed': 'bg-destructive/10 text-destructive border-destructive/20',
    'Rejected': 'bg-destructive/10 text-destructive border-destructive/20',
    'Suspended': 'bg-destructive/10 text-destructive border-destructive/20',
    'Inactive': 'bg-muted text-muted-foreground border-border',
    'Open': 'bg-warning/10 text-warning border-warning/20',
    'In Review': 'bg-primary/10 text-primary border-primary/20',
    'Resolved': 'bg-success/10 text-success border-success/20',
    'Completing': 'bg-secondary/10 text-secondary border-secondary/20',
  };

  return (
    <Badge 
      variant="outline" 
      className={cn('font-medium', variants[status] || 'bg-muted text-muted-foreground', className)}
    >
      {status}
    </Badge>
  );
}
