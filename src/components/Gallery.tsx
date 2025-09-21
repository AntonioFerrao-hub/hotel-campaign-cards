import React, { useState } from 'react';
import { useCampaigns } from '@/contexts/CampaignContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Search, Filter, Hotel, MapPin, Calendar, Users, Star } from 'lucide-react';
import { Link } from 'react-router-dom';
export const Gallery: React.FC = () => {
  const {
    campaigns
  } = useCampaigns();
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const categories = Array.from(new Set(campaigns.map(c => c.category)));
  const filteredCampaigns = campaigns.filter(campaign => {
    const matchesSearch = campaign.title.toLowerCase().includes(searchTerm.toLowerCase()) || campaign.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = selectedCategory === '' || campaign.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });
  return <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border bg-card shadow-sm">
        <div className="container mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="h-12 w-12 rounded-full bg-ocean-primary flex items-center justify-center">
                <Hotel className="h-6 w-6 text-primary-foreground" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-card-foreground">Hotéis & Resorts</h1>
                <p className="text-sm text-muted-foreground">Descubra experiências únicas</p>
              </div>
            </div>
            <Link to="/admin">
              <Button variant="outline" className="gap-2">
                Área Administrativa
              </Button>
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="bg-gradient-ocean text-primary-foreground py-12">
        
      </section>

      {/* Search and Filters */}
      <section className="container mx-auto px-4 py-8">
        <div className="flex flex-col sm:flex-row gap-4 mb-8">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
            
          </div>
          <div className="flex flex-wrap gap-2 items-center">
            <Filter className="h-4 w-4 text-muted-foreground" />
            <Badge variant={selectedCategory === '' ? 'default' : 'outline'} className="cursor-pointer" onClick={() => setSelectedCategory('')}>
              Todas
            </Badge>
            {categories.map(category => <Badge key={category} variant={selectedCategory === category ? 'default' : 'outline'} className="cursor-pointer" onClick={() => setSelectedCategory(category)}>
                {category}
              </Badge>)}
          </div>
        </div>

        {/* Results Count */}
        <div className="mb-6">
          <p className="text-muted-foreground">
            {filteredCampaigns.length} campanha(s) encontrada(s)
          </p>
        </div>

        {/* Campaigns Grid */}
        {filteredCampaigns.length > 0 ? <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredCampaigns.map(campaign => <Card key={campaign.id} className="overflow-hidden hover:shadow-elegant transition-all duration-300 hover:scale-105">
                <div className="aspect-video relative overflow-hidden">
                  <img src={campaign.image} alt={campaign.title} className="w-full h-full object-cover" />
                  <div className="absolute top-4 right-4">
                    <Badge className="bg-ocean-primary text-primary-foreground">
                      {campaign.category}
                    </Badge>
                  </div>
                </div>
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <CardTitle className="text-lg mb-1">{campaign.title}</CardTitle>
                      <div className="flex items-center gap-1 text-muted-foreground mb-2">
                        <MapPin className="h-4 w-4" />
                        <span className="text-sm">{campaign.location}</span>
                      </div>
                    </div>
                    <div className="flex items-center gap-1">
                      <Star className="h-4 w-4 fill-sand-primary text-sand-primary" />
                      <span className="text-sm font-medium">4.8</span>
                    </div>
                  </div>
                  <CardDescription className="line-clamp-2">
                    {campaign.description}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between text-sm">
                      <div className="flex items-center gap-1 text-muted-foreground">
                        <Calendar className="h-4 w-4" />
                        <span>Válida até {new Date(campaign.endDate).toLocaleDateString('pt-BR')}</span>
                      </div>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <div className="flex items-center gap-1 text-muted-foreground">
                        <Users className="h-4 w-4" />
                        <span>Máx. {campaign.maxGuests} hóspedes</span>
                      </div>
                      <div className="text-right">
                        <div className="text-lg font-bold text-ocean-primary">
                          R$ {campaign.price}
                        </div>
                        <div className="text-xs text-muted-foreground">por noite</div>
                      </div>
                    </div>
                    <Button className="w-full bg-ocean-primary hover:bg-ocean-dark">
                      Ver Detalhes
                    </Button>
                  </div>
                </CardContent>
              </Card>)}
          </div> : <div className="text-center py-12">
            <div className="h-24 w-24 mx-auto mb-4 rounded-full bg-muted flex items-center justify-center">
              <Hotel className="h-8 w-8 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-semibold text-foreground mb-2">
              Nenhuma campanha encontrada
            </h3>
            <p className="text-muted-foreground">
              Tente ajustar os filtros de busca
            </p>
          </div>}
      </section>
    </div>;
};