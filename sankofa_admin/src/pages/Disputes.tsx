import React from 'react';

import {
  mockDisputes,
  mockSupportArticles,
} from '@/lib/mockData';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/badge-variants';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Separator } from '@/components/ui/separator';
import {
  AlertTriangle,
  Calendar,
  Clock,
  ExternalLink,
  FileText,
  Mail,
  MessageSquare,
  Paperclip,
  Phone,
  Search,
  Send,
  User,
  Users,
} from 'lucide-react';

const severityOptions = ['Critical', 'High', 'Medium', 'Low'] as const;
const slaOptions = [
  { value: 'all', label: 'All SLA states' },
  { value: 'on-track', label: 'On track' },
  { value: 'at-risk', label: 'At risk' },
  { value: 'breached', label: 'Breached' },
] as const;

type Dispute = (typeof mockDisputes)[number];

type SlaFilter = (typeof slaOptions)[number]['value'];

type SeverityFilter = 'all' | (typeof severityOptions)[number];

const severityStyles: Record<string, string> = {
  Critical: 'bg-destructive/10 text-destructive border-destructive/20',
  High: 'bg-warning/10 text-warning border-warning/20',
  Medium: 'bg-primary/10 text-primary border-primary/20',
  Low: 'bg-muted text-muted-foreground border-border',
};

const slaStyles: Record<string, string> = {
  'On Track': 'bg-success/10 text-success border-success/20',
  'At Risk': 'bg-warning/10 text-warning border-warning/20',
  Breached: 'bg-destructive/10 text-destructive border-destructive/20',
};

function formatCountdown(isoDate: string) {
  const due = new Date(isoDate);
  const diffMs = due.getTime() - Date.now();
  const absDiff = Math.abs(diffMs);
  const hours = Math.floor(absDiff / (1000 * 60 * 60));
  const minutes = Math.floor((absDiff % (1000 * 60 * 60)) / (1000 * 60));
  const parts = [] as string[];
  if (hours > 0) {
    parts.push(`${hours}h`);
  }
  parts.push(`${minutes.toString().padStart(2, '0')}m`);
  if (diffMs >= 0) {
    return `Due in ${parts.join(' ')}`;
  }
  return `Overdue by ${parts.join(' ')}`;
}

function formatTimestamp(isoDate: string, withTimeZone = false) {
  const date = new Date(isoDate);
  return new Intl.DateTimeFormat('en-GB', {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    timeZoneName: withTimeZone ? 'short' : undefined,
  }).format(date);
}

function matchSlaFilter(dispute: Dispute, filter: SlaFilter) {
  if (filter === 'all') {
    return true;
  }
  if (filter === 'breached') {
    return dispute.slaStatus === 'Breached';
  }
  if (filter === 'at-risk') {
    return dispute.slaStatus === 'At Risk';
  }
  if (filter === 'on-track') {
    return dispute.slaStatus === 'On Track';
  }
  return true;
}

export default function Disputes() {
  const [severityFilter, setSeverityFilter] = React.useState<SeverityFilter>('all');
  const [slaFilter, setSlaFilter] = React.useState<SlaFilter>('all');
  const [supportQuery, setSupportQuery] = React.useState('');
  const [supportCategory, setSupportCategory] = React.useState('all');

  const faqCategories = React.useMemo(
    () => Array.from(new Set(mockSupportArticles.map((article) => article.category))),
    [],
  );

  const filteredDisputes = React.useMemo(() => {
    return mockDisputes.filter((dispute) => {
      const matchesSeverity =
        severityFilter === 'all' || dispute.severity?.toLowerCase() === severityFilter.toLowerCase();
      const matchesSla = matchSlaFilter(dispute, slaFilter);
      return matchesSeverity && matchesSla;
    });
  }, [severityFilter, slaFilter]);

  const filteredArticles = React.useMemo(() => {
    return mockSupportArticles.filter((article) => {
      const matchesCategory =
        supportCategory === 'all' || article.category.toLowerCase() === supportCategory.toLowerCase();
      const query = supportQuery.trim().toLowerCase();
      const matchesQuery =
        query.length === 0 ||
        article.title.toLowerCase().includes(query) ||
        article.summary.toLowerCase().includes(query) ||
        article.tags.some((tag) => tag.toLowerCase().includes(query));
      return matchesCategory && matchesQuery;
    });
  }, [supportCategory, supportQuery]);

  return (
    <div className="space-y-6">
      <div className="grid gap-6 lg:grid-cols-[3fr_2fr]">
        <Card className="shadow-custom-md">
          <CardHeader>
            <CardTitle>Dispute & Support Desk</CardTitle>
            <CardDescription>
              Triage member disputes, monitor SLA risk, and action escalations alongside the knowledge base.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
              <div className="space-y-2">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Severity</p>
                <ToggleGroup
                  type="single"
                  value={severityFilter}
                  onValueChange={(value) => setSeverityFilter((value as SeverityFilter) || 'all')}
                  className="flex flex-wrap justify-start gap-2"
                >
                  <ToggleGroupItem value="all" className="capitalize">
                    All
                  </ToggleGroupItem>
                  {severityOptions.map((option) => (
                    <ToggleGroupItem key={option} value={option} className="capitalize">
                      {option}
                    </ToggleGroupItem>
                  ))}
                </ToggleGroup>
              </div>
              <div className="space-y-2">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">SLA status</p>
                <ToggleGroup
                  type="single"
                  value={slaFilter}
                  onValueChange={(value) => setSlaFilter((value as SlaFilter) || 'all')}
                  className="flex flex-wrap justify-end gap-2"
                >
                  {slaOptions.map((option) => (
                    <ToggleGroupItem key={option.value} value={option.value} className="capitalize">
                      {option.label}
                    </ToggleGroupItem>
                  ))}
                </ToggleGroup>
              </div>
            </div>

            <div className="space-y-4">
              {filteredDisputes.map((dispute) => (
                <Card
                  key={dispute.id}
                  className="border-2 border-transparent shadow-custom-sm transition-smooth hover:border-primary/20"
                >
                  <CardContent className="space-y-4 p-6">
                    <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
                      <div className="space-y-3">
                        <div className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
                          <span className="font-semibold text-foreground">#{dispute.id}</span>
                          <Badge
                            variant="outline"
                            className={`font-medium ${severityStyles[dispute.severity || ''] || 'bg-muted text-muted-foreground border-border'}`}
                          >
                            {dispute.severity}
                          </Badge>
                          <StatusBadge status={dispute.status} />
                          <Badge variant="outline" className="font-medium">
                            {dispute.category}
                          </Badge>
                        </div>
                        <h3 className="text-lg font-semibold text-foreground">{dispute.title}</h3>
                        <div className="grid gap-3 text-sm text-muted-foreground sm:grid-cols-2 lg:grid-cols-3">
                          <div className="flex items-center gap-2">
                            <User className="h-4 w-4" />
                            <span>{dispute.user}</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <Users className="h-4 w-4" />
                            <span>{dispute.group}</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <Calendar className="h-4 w-4" />
                            <span>Opened {formatTimestamp(dispute.openedAt)}</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <Mail className="h-4 w-4" />
                            <span>{dispute.channel}</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <AlertTriangle className="h-4 w-4 text-warning" />
                            <span>Assigned to {dispute.assignedTo}</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <FileText className="h-4 w-4" />
                            <span>Updated {formatTimestamp(dispute.lastUpdated)}</span>
                          </div>
                        </div>
                      </div>
                      <div className="flex flex-col items-start gap-2 rounded-lg border border-border px-4 py-3 text-sm md:items-end">
                        <Badge
                          variant="outline"
                          className={`w-full justify-center font-semibold md:w-auto ${
                            slaStyles[dispute.slaStatus] || 'bg-muted text-muted-foreground border-border'
                          }`}
                        >
                          {dispute.slaStatus}
                        </Badge>
                        <div className="flex items-center gap-2 text-muted-foreground">
                          <Clock className="h-4 w-4" />
                          <span>{formatCountdown(dispute.slaDue)}</span>
                        </div>
                        <span className="text-xs text-muted-foreground">
                          SLA due {formatTimestamp(dispute.slaDue, true)}
                        </span>
                      </div>
                    </div>

                    <div className="flex flex-wrap gap-2">
                      <Dialog>
                        <DialogTrigger asChild>
                          <Button size="sm">
                            <MessageSquare className="mr-2 h-4 w-4" /> View Case
                          </Button>
                        </DialogTrigger>
                        <DialogContent className="max-w-3xl">
                          <DialogHeader>
                            <DialogTitle>{dispute.title}</DialogTitle>
                            <DialogDescription>
                              Review the conversation timeline, attachments, and escalation controls for this dispute.
                            </DialogDescription>
                          </DialogHeader>
                          <ScrollArea className="max-h-[60vh] pr-4">
                            <div className="space-y-6 py-1">
                              <div className="grid gap-4 sm:grid-cols-2">
                                <div className="space-y-1 text-sm">
                                  <p className="text-xs font-medium text-muted-foreground">Member</p>
                                  <p className="text-base font-semibold text-foreground">{dispute.user}</p>
                                </div>
                                <div className="space-y-1 text-sm">
                                  <p className="text-xs font-medium text-muted-foreground">Group</p>
                                  <p className="text-base font-semibold text-foreground">{dispute.group}</p>
                                </div>
                                <div className="space-y-1 text-sm">
                                  <p className="text-xs font-medium text-muted-foreground">SLA status</p>
                                  <Badge
                                    variant="outline"
                                    className={`font-semibold ${
                                      slaStyles[dispute.slaStatus] || 'bg-muted text-muted-foreground border-border'
                                    }`}
                                  >
                                    {dispute.slaStatus}
                                  </Badge>
                                </div>
                                <div className="space-y-1 text-sm">
                                  <p className="text-xs font-medium text-muted-foreground">Assigned owner</p>
                                  <p className="text-base font-semibold text-foreground">{dispute.assignedTo}</p>
                                </div>
                              </div>

                              <div className="space-y-3 rounded-lg border border-border p-4">
                                <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                                  <h4 className="text-sm font-semibold text-foreground">Conversation timeline</h4>
                                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                    <Clock className="h-3.5 w-3.5" /> Last updated {formatTimestamp(dispute.lastUpdated)}
                                  </div>
                                </div>
                                <div className="space-y-3">
                                  {dispute.conversation.map((entry) => (
                                    <div
                                      key={entry.id}
                                      className="rounded-md border border-border/80 bg-muted/40 p-3 text-sm text-muted-foreground"
                                    >
                                      <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-muted-foreground">
                                        <span className="font-semibold text-foreground">{entry.author}</span>
                                        <span>{formatTimestamp(entry.timestamp)}</span>
                                      </div>
                                      <p className="mt-2 leading-relaxed text-foreground">{entry.message}</p>
                                      <div className="mt-2 flex items-center gap-2 text-xs text-muted-foreground">
                                        <Send className="h-3.5 w-3.5" /> {entry.role} · {entry.channel}
                                      </div>
                                    </div>
                                  ))}
                                </div>
                              </div>

                              <div className="space-y-3">
                                <h4 className="text-sm font-semibold text-foreground">Attachments</h4>
                                <div className="grid gap-3 sm:grid-cols-2">
                                  {dispute.attachments.map((file) => (
                                    <div
                                      key={file.id}
                                      className="flex items-center justify-between gap-3 rounded-lg border border-border/80 bg-muted/30 p-3 text-sm"
                                    >
                                      <div className="flex items-center gap-3">
                                        <Paperclip className="h-4 w-4 text-muted-foreground" />
                                        <div>
                                          <p className="font-medium text-foreground">{file.fileName}</p>
                                          <p className="text-xs text-muted-foreground">
                                            {file.type} · {file.size}
                                          </p>
                                        </div>
                                      </div>
                                      <Button variant="ghost" size="icon" aria-label="Download attachment">
                                        <ExternalLink className="h-4 w-4" />
                                      </Button>
                                    </div>
                                  ))}
                                </div>
                              </div>

                              <Separator />

                              <div className="space-y-4">
                                <div className="grid gap-4 sm:grid-cols-2">
                                  <div className="space-y-2">
                                    <Label htmlFor={`escalation-${dispute.id}`}>Escalate to</Label>
                                    <Select defaultValue="risk">
                                      <SelectTrigger id={`escalation-${dispute.id}`}>
                                        <SelectValue placeholder="Select escalation destination" />
                                      </SelectTrigger>
                                      <SelectContent>
                                        <SelectItem value="risk">Risk & Compliance Desk</SelectItem>
                                        <SelectItem value="finance">Finance & Treasury</SelectItem>
                                        <SelectItem value="legal">Legal Counsel</SelectItem>
                                      </SelectContent>
                                    </Select>
                                  </div>
                                  <div className="space-y-2">
                                    <Label htmlFor={`channel-${dispute.id}`}>Notify via</Label>
                                    <Select defaultValue="email">
                                      <SelectTrigger id={`channel-${dispute.id}`}>
                                        <SelectValue placeholder="Select channel" />
                                      </SelectTrigger>
                                      <SelectContent>
                                        <SelectItem value="email">Email</SelectItem>
                                        <SelectItem value="phone">Phone</SelectItem>
                                        <SelectItem value="in-app">In-app Alert</SelectItem>
                                      </SelectContent>
                                    </Select>
                                  </div>
                                </div>
                                <div className="space-y-2">
                                  <Label htmlFor={`resolution-${dispute.id}`}>Resolution notes</Label>
                                  <Textarea
                                    id={`resolution-${dispute.id}`}
                                    placeholder="Log the latest investigation updates, refunds, or pending actions..."
                                    className="min-h-[120px]"
                                  />
                                </div>
                              </div>

                              {dispute.relatedFaqId && (
                                <div className="space-y-2 rounded-lg border border-dashed border-primary/40 bg-primary/5 p-4">
                                  <p className="text-sm font-semibold text-primary">Related knowledge base article</p>
                                  {(() => {
                                    const relatedArticle = mockSupportArticles.find(
                                      (article) => article.id === dispute.relatedFaqId,
                                    );
                                    if (!relatedArticle) return null;
                                    return (
                                      <div className="flex flex-wrap items-center justify-between gap-3 text-sm">
                                        <div>
                                          <p className="font-medium text-foreground">{relatedArticle.title}</p>
                                          <p className="text-xs text-muted-foreground">{relatedArticle.summary}</p>
                                        </div>
                                        <Button asChild size="sm" variant="outline">
                                          <a href={relatedArticle.link} target="_blank" rel="noreferrer">
                                            View playbook
                                            <ExternalLink className="ml-2 h-3.5 w-3.5" />
                                          </a>
                                        </Button>
                                      </div>
                                    );
                                  })()}
                                </div>
                              )}
                            </div>
                          </ScrollArea>
                          <div className="flex flex-col gap-2 border-t border-border pt-4 sm:flex-row sm:justify-end">
                            <Button variant="outline">
                              <Phone className="mr-2 h-4 w-4" /> Log Call Back
                            </Button>
                            <Button variant="ghost">
                              <Send className="mr-2 h-4 w-4" /> Request More Info
                            </Button>
                            <Button variant="destructive">
                              <AlertTriangle className="mr-2 h-4 w-4" /> Escalate
                            </Button>
                            <Button>
                              <MessageSquare className="mr-2 h-4 w-4" /> Mark Resolved
                            </Button>
                          </div>
                        </DialogContent>
                      </Dialog>
                      <Button variant="outline" size="sm">
                        <Phone className="mr-2 h-4 w-4" /> Log outreach
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}

              {filteredDisputes.length === 0 && (
                <div className="rounded-lg border border-dashed border-border px-6 py-10 text-center text-sm text-muted-foreground">
                  No disputes match the selected filters. Adjust severity or SLA filters to view more cases.
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-custom-md">
          <CardHeader>
            <CardTitle>Support Knowledge Base</CardTitle>
            <CardDescription>
              Surface the same FAQ taxonomy members see in the app to power consistent guidance and self-serve replies.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-5">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={supportQuery}
                onChange={(event) => setSupportQuery(event.target.value)}
                placeholder="Search articles, tags, or playbooks"
                className="pl-9"
              />
            </div>

            <div className="space-y-2">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Categories</p>
              <ToggleGroup
                type="single"
                value={supportCategory}
                onValueChange={(value) => setSupportCategory(value || 'all')}
                className="flex flex-wrap gap-2"
              >
                <ToggleGroupItem value="all" className="capitalize">
                  All
                </ToggleGroupItem>
                {faqCategories.map((category) => (
                  <ToggleGroupItem key={category} value={category} className="capitalize">
                    {category}
                  </ToggleGroupItem>
                ))}
              </ToggleGroup>
            </div>

            <ScrollArea className="h-[520px] pr-4">
              <div className="space-y-4">
                {filteredArticles.map((article) => (
                  <div
                    key={article.id}
                    className="space-y-3 rounded-lg border border-border/80 bg-muted/30 p-4 transition-smooth hover:border-primary/30"
                  >
                    <div className="flex flex-wrap items-start justify-between gap-3">
                      <div className="space-y-1">
                        <Badge variant="outline" className="font-medium">
                          {article.category}
                        </Badge>
                        <h4 className="text-base font-semibold text-foreground">{article.title}</h4>
                        <p className="text-sm text-muted-foreground">{article.summary}</p>
                      </div>
                      <Button asChild variant="ghost" size="sm">
                        <a href={article.link} target="_blank" rel="noreferrer">
                          Open
                          <ExternalLink className="ml-2 h-4 w-4" />
                        </a>
                      </Button>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {article.tags.map((tag) => (
                        <Badge key={`${article.id}-${tag}`} variant="secondary" className="capitalize">
                          {tag}
                        </Badge>
                      ))}
                    </div>
                  </div>
                ))}

                {filteredArticles.length === 0 && (
                  <div className="rounded-lg border border-dashed border-border px-6 py-10 text-center text-sm text-muted-foreground">
                    No articles found. Try a different keyword or category.
                  </div>
                )}
              </div>
            </ScrollArea>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
