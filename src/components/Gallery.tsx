import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useCampaigns } from '@/contexts/CampaignContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Search, Filter, Hotel } from 'lucide-react';
import { CampaignCard } from '@/components/CampaignCard';
import { supabase } from '@/integrations/supabase/client';
import type { Campaign } from '@/types/campaign';

interface Category {
  id: string;
  name: string;
  display_order: number;
}

export const Gallery: React.FC = () => {
  const { campaigns, autoDeactivateExpired } = useCampaigns();
  const [searchParams, setSearchParams] = useSearchParams();
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [orderedCategories, setOrderedCategories] = useState<Category[]>([]);
  

  // Fetch categories with custom ordering
  const fetchOrderedCategories = async () => {
    try {
      const { data, error } = await supabase
        .from('categories')
        .select('id, name, display_order')
        .order('display_order');

      if (error) {
        console.error('Erro ao buscar categorias:', error);
        return;
      }

      setOrderedCategories(data || []);
    } catch (error) {
      console.error('Erro inesperado ao buscar categorias:', error);
    }
  };

  useEffect(() => {
    fetchOrderedCategories();
  }, []);

  useEffect(() => {
    // Desativar automaticamente campanhas expiradas ao entrar na página
    (async () => {
      try {
        await autoDeactivateExpired();
      } catch (e) {
        console.error('Erro ao desativar campanhas expiradas automaticamente:', e);
      }
    })();
    const savedCategory = localStorage.getItem('gallery_category') || '';
    const savedSearch = localStorage.getItem('gallery_search') || '';
    setSelectedCategory(savedCategory);
    setSearchTerm(savedSearch);
  }, []);

  // Get all unique categories from campaigns that exist in our ordered categories
  const availableCategories = orderedCategories.filter(category => 
    campaigns.some(campaign => 
      campaign.category === category.name || 
      (campaign.categories && campaign.categories.some(cat => cat.name === category.name))
    )
  );

  // Sincronizar com parâmetros de URL
  useEffect(() => {
    const categoryParam = searchParams.get('category');
    const searchParam = searchParams.get('search');
    
    if (categoryParam) {
      setSelectedCategory(categoryParam);
      localStorage.setItem('gallery_category', categoryParam);
    }
    if (searchParam) {
      setSearchTerm(searchParam);
      localStorage.setItem('gallery_search', searchParam);
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
    localStorage.setItem('gallery_category', category);
    updateURLParams(category, searchTerm);
  };

  const handleSearchChange = (search: string) => {
    setSearchTerm(search);
    localStorage.setItem('gallery_search', search);
    updateURLParams(selectedCategory, search);
  };

  const filteredCampaigns: Campaign[] = campaigns.filter((campaign: Campaign) => {
    const matchesSearch = campaign.title.toLowerCase().includes(searchTerm.toLowerCase()) || 
                         campaign.description.toLowerCase().includes(searchTerm.toLowerCase());
    
    // Check if campaign matches selected category (either in single category or categories array)
    const matchesCategory = selectedCategory === '' || 
                           campaign.category === selectedCategory ||
                           (campaign.categories && campaign.categories.some(cat => cat.name === selectedCategory));
    const isActive = campaign.status === 'active';
    return matchesSearch && matchesCategory && isActive;
  });

  const sortedCampaigns: Campaign[] = filteredCampaigns.slice().sort((a, b) => {
    const aStart = a.startDate ? new Date(a.startDate).getTime() : 0;
    const bStart = b.startDate ? new Date(b.startDate).getTime() : 0;
    return bStart - aStart; // mais recentes primeiro
  });

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="border-b border-gray-200 bg-white shadow-sm">
      </header>

      <section className="container mx-auto px-4 py-8">
        <div className="flex flex-col gap-4 mb-8">
          <div className="flex flex-wrap gap-2 items-center">
            <Badge 
              variant={selectedCategory === '' ? 'default' : 'outline'} 
              className="cursor-pointer" 
              onClick={() => handleCategoryChange('')}
            >
              Todas
            </Badge>
            {availableCategories.map(category => (
              <Badge 
                key={category.id} 
                variant={selectedCategory === category.name ? 'default' : 'outline'} 
                className="cursor-pointer" 
                onClick={() => handleCategoryChange(category.name)}
              >
                {category.name}
              </Badge>
            ))}
          </div>
        </div>

        {/* Results Count */}
        <div className="mb-6">
          <p className="text-sm text-gray-600">
            {filteredCampaigns.length} {filteredCampaigns.length === 1 ? 'campanha encontrada' : 'campanhas encontradas'}
            {selectedCategory && ` na categoria "${selectedCategory}"`}
          </p>
        </div>

        {/* Campaigns Grid */}
        {filteredCampaigns.length > 0 ? (
          <div className="w-full">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5 justify-items-center px-4">
              {sortedCampaigns.map(campaign => (
                <CampaignCard key={campaign.id} campaign={campaign} showActions={false} />
              ))}
            </div>
          </div>
        ) : (
          <div className="text-center py-12">
            <div className="h-24 w-24 mx-auto mb-4 rounded-full bg-gray-100 flex items-center justify-center">
              <Hotel className="h-12 w-12 text-gray-400" />
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              Nenhuma campanha encontrada
            </h3>
            <p className="text-gray-600">
              {selectedCategory 
                ? `Não há campanhas na categoria "${selectedCategory}"`
                : 'Tente ajustar os filtros de busca'
              }
            </p>
          </div>
        )}
      </section>
    </div>
  );
};
