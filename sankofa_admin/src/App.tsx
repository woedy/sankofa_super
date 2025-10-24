import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { useState } from "react";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import Users from "./pages/Users";
import Groups from "./pages/Groups";
import Transactions from "./pages/Transactions";
import Analytics from "./pages/Analytics";
import Disputes from "./pages/Disputes";
import Settings from "./pages/Settings";
import Cashflow from "./pages/Cashflow";
import Sidebar from "./components/layout/Sidebar";
import Header from "./components/layout/Header";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

// Layout component for authenticated pages
function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen w-full overflow-hidden bg-background">
      <Sidebar />
      <div className="flex flex-1 flex-col overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  );
}

const App = () => {
  // In a real app, this would be managed by auth context
  const [isAuthenticated] = useState(true);

  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<Login />} />
            
            {/* Protected routes with layout */}
            <Route path="/" element={
              isAuthenticated ? (
                <DashboardLayout>
                  <Dashboard />
                </DashboardLayout>
              ) : (
                <Navigate to="/login" replace />
              )
            } />
            
            <Route path="/users" element={
              isAuthenticated ? (
                <DashboardLayout>
                  <Users />
                </DashboardLayout>
              ) : (
                <Navigate to="/login" replace />
              )
            } />
            
            <Route path="/groups" element={
              isAuthenticated ? (
                <DashboardLayout>
                  <Groups />
                </DashboardLayout>
              ) : (
                <Navigate to="/login" replace />
              )
            } />

            <Route path="/cashflow" element={
              isAuthenticated ? (
                <DashboardLayout>
                  <Cashflow />
                </DashboardLayout>
              ) : (
                <Navigate to="/login" replace />
              )
            } />

            <Route path="/transactions" element={
              isAuthenticated ? (
                <DashboardLayout>
                  <Transactions />
                </DashboardLayout>
              ) : (
                <Navigate to="/login" replace />
              )
            } />
            
            <Route path="/analytics" element={
              isAuthenticated ? (
                <DashboardLayout>
                  <Analytics />
                </DashboardLayout>
              ) : (
                <Navigate to="/login" replace />
              )
            } />
            
            <Route path="/disputes" element={
              isAuthenticated ? (
                <DashboardLayout>
                  <Disputes />
                </DashboardLayout>
              ) : (
                <Navigate to="/login" replace />
              )
            } />
            
            <Route path="/settings" element={
              isAuthenticated ? (
                <DashboardLayout>
                  <Settings />
                </DashboardLayout>
              ) : (
                <Navigate to="/login" replace />
              )
            } />
            
            {/* Catch-all route */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </BrowserRouter>
      </TooltipProvider>
    </QueryClientProvider>
  );
};

export default App;
