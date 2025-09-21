import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Campaign } from '@/types/campaign';
import { supabase } from '@/integrations/supabase/client';

interface CampaignContextType {
  campaigns: Campaign[];
  addCampaign: (campaign: Omit<Campaign, 'id'>) => Promise<void>;
  updateCampaign: (id: string, campaign: Partial<Campaign>) => Promise<void>;
  deleteCampaign: (id: string) => void;
  getCampaign: (id: string) => Campaign | undefined;
  loading: boolean;
  refetch: () => Promise<void>;
}

const CampaignContext = createContext<CampaignContextType | undefined>(undefined);

export const useCampaigns = () => {
  const context = useContext(CampaignContext);
  if (context === undefined) {
    throw new Error('useCampaigns must be used within a CampaignProvider');
  }
  return context;
};

interface CampaignProviderProps {
  children: ReactNode;
}

export const CampaignProvider: React.FC<CampaignProviderProps> = ({ children }) => {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchCampaigns = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('campaigns')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Erro ao buscar campanhas:', error);
        return;
      }

      // Mapear dados do Supabase para o formato esperado
      const mappedCampaigns: Campaign[] = (data || []).map(campaign => ({
        id: campaign.id,
        title: campaign.title,
        description: campaign.description || '',
        priceOriginal: campaign.price_original || 0,
        pricePromotional: campaign.price_promotional || 0,
        priceLabel: 'A partir de',
        image: '', // Será necessário adicionar campo de imagem na tabela
        startDate: campaign.start_date || '',
        endDate: campaign.end_date || '',
        duration: '2 diárias', // Valor padrão, pode ser calculado
        status: campaign.is_active ? 'active' : 'inactive',
        category: 'Temporada', // Valor padrão, será necessário adicionar campo
        location: 'São Paulo, SP', // Valor padrão, será necessário adicionar campo
        maxGuests: 4, // Valor padrão, será necessário adicionar campo
      }));

      setCampaigns(mappedCampaigns);
    } catch (error) {
      console.error('Erro inesperado ao buscar campanhas:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCampaigns();
  }, []);

  const addCampaign = async (campaign: Omit<Campaign, 'id'>) => {
    try {
      const { error } = await supabase
        .from('campaigns')
        .insert({
          title: campaign.title,
          description: campaign.description,
          price_original: campaign.priceOriginal,
          price_promotional: campaign.pricePromotional,
          start_date: campaign.startDate,
          end_date: campaign.endDate,
          is_active: campaign.status === 'active',
          hotel_id: '00000000-0000-0000-0000-000000000000' // Valor temporário
        });

      if (error) {
        throw error;
      }

      // Recarregar campanhas
      await fetchCampaigns();
    } catch (error) {
      console.error('Erro ao adicionar campanha:', error);
      throw error;
    }
  };

  const updateCampaign = async (id: string, updatedCampaign: Partial<Campaign>) => {
    try {
      const { error } = await supabase
        .from('campaigns')
        .update({
          title: updatedCampaign.title,
          description: updatedCampaign.description,
          price_original: updatedCampaign.priceOriginal,
          price_promotional: updatedCampaign.pricePromotional,
          start_date: updatedCampaign.startDate,
          end_date: updatedCampaign.endDate,
          is_active: updatedCampaign.status === 'active',
        })
        .eq('id', id);

      if (error) {
        throw error;
      }

      // Recarregar campanhas
      await fetchCampaigns();
    } catch (error) {
      console.error('Erro ao atualizar campanha:', error);
      throw error;
    }
  };

  const deleteCampaign = (id: string) => {
    setCampaigns(prev => prev.filter(campaign => campaign.id !== id));
  };

  const getCampaign = (id: string) => {
    return campaigns.find(campaign => campaign.id === id);
  };

  return (
    <CampaignContext.Provider value={{
      campaigns,
      addCampaign,
      updateCampaign,
      deleteCampaign,
      getCampaign,
      loading,
      refetch: fetchCampaigns
    }}>
      {children}
    </CampaignContext.Provider>
  );
};