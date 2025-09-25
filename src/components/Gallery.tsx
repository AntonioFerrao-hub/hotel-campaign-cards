import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useCampaigns } from '@/contexts/CampaignContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Search, Filter, Hotel } from 'lucide-react';
import { CampaignCard } from '@/components/CampaignCard';

export const Gallery: React.FC = () => {
  const { campaigns } = useCampaigns();
  const [searchParams, setSearchParams] = useSearchParams();
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('');

  const categories = Array.from(new Set(campaigns.map(c => c.category).filter(Boolean)));

  // Sincronizar com parâmetros de URL
  useEffect(() => {
    const categoryParam = searchParams.get('category');
    const searchParam = searchParams.get('search');
    
    if (categoryParam) {
      setSelectedCategory(categoryParam);
    }
    if (searchParam) {
      setSearchTerm(searchParam);
    }
  }, [searchParams]);

  // Atualizar URL quando filtros mudarem
  const updateURLParams = (category: string, search: string) => {
    const newParams = new URLSearchParams();
    
    if (category) {
      newParams.set('category', category);
    }
    if (search) {
      newParams.set('search', search);
    }
    
    setSearchParams(newParams);
  };

  const handleCategoryChange = (category: string) => {
    setSelectedCategory(category);
    updateURLParams(category, searchTerm);
  };

  const handleSearchChange = (search: string) => {
    setSearchTerm(search);
    updateURLParams(selectedCategory, search);
  };

  const filteredCampaigns = campaigns.filter(campaign => {
    const matchesSearch = campaign.title.toLowerCase().includes(searchTerm.toLowerCase()) || 
                         campaign.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = selectedCategory === '' || campaign.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="border-b border-gray-200 bg-white shadow-sm">
      </header>

      {/* Search and Filters */}
      <section className="container mx-auto px-4 py-8">
        <div className="flex flex-col sm:flex-row gap-4 mb-8">
          {/* Category Filters */}
          <div className="flex flex-wrap gap-2 items-center">
            <Badge 
              variant={selectedCategory === '' ? 'default' : 'outline'} 
              className="cursor-pointer" 
              onClick={() => handleCategoryChange('')}
            >
              Todas
            </Badge>
            {categories.map(category => (
              <Badge 
                key={category} 
                variant={selectedCategory === category ? 'default' : 'outline'} 
                className="cursor-pointer" 
                onClick={() => handleCategoryChange(category)}
              >
                {category}
              </Badge>
            ))}
          </div>
        </div>

        {/* Results Count */}
        <div className="mb-6">
        </div>

        {/* Campaigns Grid */}
        {filteredCampaigns.length > 0 ? (
          <div className="w-full">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5 justify-items-center px-4">
              {filteredCampaigns.map(campaign => (
                <CampaignCard key={campaign.id} campaign={campaign} showActions={false} />
              ))}
            </div>
          </div>
        ) : (
          <div className="text-center py-12">
            <div className="h-24 w-24 mx-auto mb-4 rounded-full bg-gray-100 flex items-center justify-center">
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              Nenhuma campanha encontrada
            </h3>
          </div>
        )}
      </section>
    </div>
  );
};