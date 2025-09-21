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
        description: campaign.description || 'Diária para dois adultos',
        priceOriginal: campaign.price_original || 0,
        pricePromotional: campaign.price_promotional || 0,
        priceLabel: campaign.price_label || 'A partir de',
        image: campaign.image_url || '/placeholder.svg',
        startDate: campaign.start_date || '',
        endDate: campaign.end_date || '',
        duration: campaign.duration_nights ? `${campaign.duration_nights} diárias` : '2 diárias',
        status: campaign.is_active ? 'active' : 'inactive',
        category: campaign.category || '',
        location: '',
        maxGuests: 0,
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
      // Calcular duration_nights a partir das datas
      let durationNights = 2; // valor padrão
      if (campaign.startDate && campaign.endDate) {
        const startDate = new Date(campaign.startDate);
        const endDate = new Date(campaign.endDate);
        const diffTime = endDate.getTime() - startDate.getTime();
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        if (diffDays > 0) {
          durationNights = diffDays;
        }
      }

      const { error } = await supabase
        .from('campaigns')
        .insert({
          title: campaign.title,
          description: campaign.description,
          price_original: campaign.priceOriginal,
          price_promotional: campaign.pricePromotional,
          price_label: campaign.priceLabel,
          start_date: campaign.startDate,
          end_date: campaign.endDate,
          duration_nights: durationNights,
          is_active: campaign.status === 'active',
          image_url: campaign.image,
          category: campaign.category
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
      // Calcular duration_nights a partir das datas se foram fornecidas
      let updateData: any = {
        title: updatedCampaign.title,
        description: updatedCampaign.description,
        price_original: updatedCampaign.priceOriginal,
        price_promotional: updatedCampaign.pricePromotional,
        price_label: updatedCampaign.priceLabel,
        start_date: updatedCampaign.startDate,
        end_date: updatedCampaign.endDate,
        is_active: updatedCampaign.status === 'active',
        image_url: updatedCampaign.image,
        category: updatedCampaign.category
      };

      if (updatedCampaign.startDate && updatedCampaign.endDate) {
        const startDate = new Date(updatedCampaign.startDate);
        const endDate = new Date(updatedCampaign.endDate);
        const diffTime = endDate.getTime() - startDate.getTime();
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        if (diffDays > 0) {
          updateData.duration_nights = diffDays;
        }
      }

      const { error } = await supabase
        .from('campaigns')
        .update(updateData)
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