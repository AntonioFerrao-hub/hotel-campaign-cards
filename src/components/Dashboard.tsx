import React, { useState } from 'react';
import { useCampaigns } from '@/contexts/CampaignContext';
import { useAuth } from '@/contexts/AuthContext';
import { CampaignCard } from './CampaignCard';
import { CampaignForm } from './CampaignForm';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { 
  Plus, 
  Search, 
  LogOut, 
  Hotel
} from 'lucide-react';
import { Campaign } from '@/types/campaign';

export const Dashboard: React.FC = () => {
  const { campaigns, loading } = useCampaigns();
  const { logout, user } = useAuth();
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [showForm, setShowForm] = useState(false);
  const [editingCampaign, setEditingCampaign] = useState<Campaign | null>(null);

  const categories = Array.from(new Set(campaigns.map(c => c.category)));

  const filteredCampaigns = campaigns.filter(campaign => {
    const matchesSearch = campaign.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         campaign.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = selectedCategory === '' || campaign.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const handleEdit = (campaign: Campaign) => {
    setEditingCampaign(campaign);
    setShowForm(true);
  };

  const handleCloseForm = () => {
    setShowForm(false);
    setEditingCampaign(null);
  };

  if (showForm) {
    return <CampaignForm campaign={editingCampaign} onClose={handleCloseForm} />;
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border bg-card shadow-sm container mx-auto px-4 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="h-10 w-10 rounded-full bg-ocean-primary flex items-center justify-center">
            <Hotel className="h-5 w-5 text-primary-foreground" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-card-foreground">CMS Campanhas</h1>
            <p className="text-sm text-muted-foreground">Bem-vindo, {user?.name}</p>
          </div>
        </div>
        <Button variant="outline" onClick={logout} className="gap-2">
          <LogOut className="h-4 w-4" />
          Sair
        </Button>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        {/* Controls */}
        <div className="mb-8 space-y-4">
          <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
            <h2 className="text-2xl font-bold text-foreground mb-2">
              Campanhas de Hotéis
            </h2>
            <p className="text-muted-foreground">
              {filteredCampaigns.length} campanha(s) encontrada(s)
            </p>
            <Button 
              onClick={() => setShowForm(true)}
              className="bg-ocean-primary hover:bg-ocean-dark gap-2"
            >
              <Plus className="h-4 w-4" />
              Nova Campanha
            </Button>
          </div>

          {/* Search and Filters */}
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Buscar campanhas..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            <Badge
              variant={selectedCategory === '' ? 'default' : 'outline'}
              className="cursor-pointer"
              onClick={() => setSelectedCategory('')}
            >
              Todas
            </Badge>
            {categories.map(category => (
              <Badge
                key={category}
                variant={selectedCategory === category ? 'default' : 'outline'}
                className="cursor-pointer"
                onClick={() => setSelectedCategory(category)}
              >
                {category}
              </Badge>
            ))}
        </div>
        </div>

        {/* Campaign Grid */}
        {loading ? (
          <div className="text-center py-12">
            <div className="h-24 w-24 mx-auto mb-4 rounded-full bg-muted flex items-center justify-center animate-pulse">
              <Hotel className="h-8 w-8 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-semibold text-foreground mb-2">
              Carregando campanhas...
            </h3>
          </div>
        ) : filteredCampaigns.length > 0 ? (
          <div className="w-full">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5 justify-items-center px-4">
              {filteredCampaigns.map(campaign => (
                <CampaignCard
                  key={campaign.id}
                  campaign={campaign}
                  showActions={true}
                  onEdit={handleEdit}
                />
              ))}
            </div>
          </div>
        ) : (
          <div className="text-center py-12">
            <div className="h-24 w-24 mx-auto mb-4 rounded-full bg-muted flex items-center justify-center">
              <Hotel className="h-8 w-8 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-semibold text-foreground mb-2">
              Nenhuma campanha encontrada
            </h3>
            <p className="text-muted-foreground mb-4">
              {searchTerm || selectedCategory 
                ? 'Tente ajustar os filtros de busca'
                : 'Comece criando sua primeira campanha'
              }
            </p>
            {!searchTerm && !selectedCategory && (
              <Button 
                onClick={() => setShowForm(true)}
                className="bg-ocean-primary hover:bg-ocean-dark"
              >
                Criar Primeira Campanha
              </Button>
            )}
          </div>
        )}
      </main>
    </div>
  );
};