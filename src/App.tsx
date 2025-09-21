import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "@/contexts/AuthContext";
import { CampaignProvider } from "@/contexts/CampaignContext";
import { Gallery } from "@/components/Gallery";
import { Dashboard } from "@/components/Dashboard";
import { AdminLayout } from "@/components/AdminLayout";
import { UserManagement } from "@/components/UserManagement";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <AuthProvider>
        <CampaignProvider>
          <BrowserRouter>
            <Routes>
              <Route path="/" element={<Gallery />} />
              <Route path="/admin/*" element={
                <AdminLayout>
                  <Routes>
                    <Route index element={<Dashboard />} />
                    <Route path="campaigns" element={<Dashboard />} />
                    <Route path="users" element={<UserManagement />} />
                  </Routes>
                </AdminLayout>
              } />
              {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
              <Route path="*" element={<NotFound />} />
            </Routes>
          </BrowserRouter>
        </CampaignProvider>
      </AuthProvider>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
